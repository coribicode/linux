import os
import shutil
import hashlib
import json
import psutil
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime, timedelta
from threading import Thread, Lock
from flask import Flask, render_template, render_template_string, request, redirect, url_for, session, jsonify, abort, flash
from werkzeug.security import check_password_hash, generate_password_hash
from apscheduler.schedulers.background import BackgroundScheduler
from jinja2 import DictLoader



# --- Configuração Inicial ---
BASE_DIR = '/opt/backupy'
DATA_DIR = '/opt/BackuPY'
CONFIG_FILE = os.path.join(BASE_DIR, 'config.json')
DB_FILE = os.path.join(BASE_DIR, 'backup_db.json')
LOG_FILE = os.path.join(BASE_DIR, 'backupy.log')

# --- Configuração do Logging ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        RotatingFileHandler(LOG_FILE, maxBytes=10485760, backupCount=5),
        logging.StreamHandler()
    ]
)

# --- Estrutura da Aplicação Flask ---
app = Flask(__name__)
app.secret_key = os.urandom(24)

# --- Status Global do Backup (Thread-Safe) ---
backup_status_lock = Lock()
backup_status = {
    'running': False,
    'progress': 0,
    'total_files': 0,
    'processed_files': 0,
    'current_file': '',
    'start_time': None,
    'task_id': None,
    'messages': []
}

# --- Templates HTML Embutidos ---

LOGIN_TEMPLATE = """
<!DOCTYPE html>
<html lang="pt-BR" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BackuPY - Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .login-card { max-width: 400px; width: 100%; }
    </style>
</head>
<body>
    <div class="card p-4 shadow-sm login-card">
        <h3 class="card-title text-center mb-4">BackuPY</h3>
        {% if error %}
            <div class="alert alert-danger">{{ error }}</div>
        {% endif %}
        <form method="post">
            <div class="mb-3">
                <label for="username" class="form-label">Usuário</label>
                <input type="text" class="form-control" id="username" name="username" required>
            </div>
            <div class="mb-3">
                <label for="password" class="form-label">Senha</label>
                <input type="password" class="form-control" id="password" name="password" required>
            </div>
            <button type="submit" class="btn btn-primary w-100">Entrar</button>
        </form>
    </div>
</body>
</html>
"""

LAYOUT_TEMPLATE = """
<!DOCTYPE html>
<html lang="pt-BR" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BackuPY - {{ title }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <style>
        body { background-color: #212529; }
        .sidebar { min-height: 100vh; }
        .nav-link { font-size: 1.1em; }
        .nav-link.active { color: #fff !important; background-color: #0d6efd; }
        .toast-container { z-index: 1080; }
        .table-hover tbody tr:hover {
            background-color: rgba(255, 255, 255, 0.075);
        }
    </style>
</head>
<body>
    <div class="d-flex">
        <nav class="d-flex flex-column flex-shrink-0 p-3 text-white bg-dark sidebar" style="width: 280px;">
            <a href="/" class="d-flex align-items-center mb-3 mb-md-0 me-md-auto text-white text-decoration-none">
                <i class="bi bi-box-seam-fill me-2 fs-4"></i>
                <span class="fs-4">BackuPY</span>
            </a>
            <hr>
            <ul class="nav nav-pills flex-column mb-auto">
                <li class="nav-item">
                    <a href="{{ url_for('index') }}" class="nav-link text-white {% if request.endpoint == 'index' %}active{% endif %}">
                        <i class="bi bi-speedometer2 me-2"></i> Dashboard
                    </a>
                </li>
                <li>
                    <a href="{{ url_for('settings') }}" class="nav-link text-white {% if request.endpoint == 'settings' %}active{% endif %}">
                        <i class="bi bi-gear-fill me-2"></i> Configurações
                    </a>
                </li>
                 <li>
                    <a href="{{ url_for('logs') }}" class="nav-link text-white {% if request.endpoint == 'logs' %}active{% endif %}">
                        <i class="bi bi-file-text-fill me-2"></i> Logs e Relatórios
                    </a>
                </li>
            </ul>
            <hr>
            <div class="dropdown">
                <a href="#" class="d-flex align-items-center text-white text-decoration-none dropdown-toggle" id="dropdownUser1" data-bs-toggle="dropdown" aria-expanded="false">
                    <i class="bi bi-person-circle fs-4 me-2"></i>
                    <strong>Admin</strong>
                </a>
                <ul class="dropdown-menu dropdown-menu-dark text-small shadow" aria-labelledby="dropdownUser1">
                    <li><a class="dropdown-item" href="{{ url_for('logout') }}">Sair</a></li>
                </ul>
            </div>
        </nav>

        <main class="w-100 p-4">
            {% block content %}{% endblock %}
        </main>
    </div>

    <!-- Toast Container for Notifications -->
    <div class="toast-container position-fixed bottom-0 end-0 p-3">
        <div id="progressToast" class="toast" role="alert" aria-live="assertive" aria-atomic="true" data-bs-autohide="false">
            <div class="toast-header">
                <strong class="me-auto"><i class="bi bi-hdd-rack-fill"></i> Tarefa de Backup em Andamento</strong>
                <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
            <div class="toast-body">
                <div id="toast-message">Iniciando backup...</div>
                <div class="progress mt-2" style="height: 20px;">
                    <div id="progressBar" class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar" style="width: 0%;" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">0%</div>
                </div>
                 <div id="toast-details" class="small mt-2 text-muted"></div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        {% block scripts %}{% endblock %}
    </script>
</body>
</html>
"""

INDEX_TEMPLATE = """
{% extends "layout.html" %}
{% block title %}Dashboard{% endblock %}
{% block content %}
<h1 class="mb-4">Dashboard</h1>

<!-- Disk Space Usage -->
<div class="row mb-4">
    {% for type, usage in disk_usage.items() %}
    <div class="col-lg-4 mb-3">
        <div class="card">
            <div class="card-header">
                <h5 class="card-title mb-0"><i class="bi bi-hdd-fill me-2"></i> Espaço - Backup {{ type }}</h5>
            </div>
            <div class="card-body">
                <p class="card-text"><strong>Caminho:</strong> <small class="text-muted">{{ usage.path }}</small></p>
                <div class="progress mb-2" style="height: 25px;">
                    <div class="progress-bar" role="progressbar" style="width: {{ usage.percent }}%;" aria-valuenow="{{ usage.percent }}" aria-valuemin="0" aria-valuemax="100">{{ usage.percent }}%</div>
                </div>
                <div class="d-flex justify-content-between">
                    <span><i class="bi bi-database-fill-up text-primary"></i> Usado: {{ "%.2f"|format(usage.used) }} GB</span>
                    <span><i class="bi bi-database-fill text-success"></i> Livre: {{ "%.2f"|format(usage.free) }} GB</span>
                    <span><i class="bi bi-database-fill-check text-info"></i> Total: {{ "%.2f"|format(usage.total) }} GB</span>
                </div>
            </div>
        </div>
    </div>
    {% endfor %}
</div>

<!-- Manual Backup & Status -->
<div class="card mb-4">
    <div class="card-header">
        <h5 class="card-title mb-0"><i class="bi bi-play-circle-fill me-2"></i> Controle de Backup</h5>
    </div>
    <div class="card-body">
        <p>Iniciar uma nova tarefa de backup manualmente:</p>
        <div class="btn-group" role="group">
            <button class="btn btn-primary" onclick="runBackup('Completo')"><i class="bi bi-file-earmark-zip-fill me-1"></i> Completo</button>
            <button class="btn btn-info" onclick="runBackup('Diferencial')"><i class="bi bi-subtract me-1"></i> Diferencial</button>
            <button class="btn btn-warning" onclick="runBackup('Incremental')"><i class="bi bi-plus-slash-minus me-1"></i> Incremental</button>
        </div>
    </div>
</div>

<!-- Backup History -->
<div class="card mb-4">
    <div class="card-header">
        <h5 class="card-title mb-0"><i class="bi bi-clock-history me-2"></i> Histórico de Backups (Últimos {{ backups|length }})</h5>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Data/Hora</th>
                        <th>Tipo</th>
                        <th>Total Arquivos</th>
                        <th>Copiados</th>
                        <th>Hardlinks</th>
                        <th>Tamanho (GB)</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {% for backup in backups %}
                    <tr style="cursor: pointer;" onclick="window.location='{{ url_for('restore_explorer', backup_id=backup.id) }}'">
                        <td>{{ backup.end_time }}</td>
                        <td>
                            <span class="badge
                                {% if backup.type == 'Completo' %} text-bg-primary
                                {% elif backup.type == 'Diferencial' %} text-bg-info
                                {% else %} text-bg-warning {% endif %}">
                                {{ backup.type }}
                            </span>
                        </td>
                        <td>{{ backup.stats.total_files }}</td>
                        <td>{{ backup.stats.files_copied }}</td>
                        <td>{{ backup.stats.hardlinks_created }}</td>
                        <td>{{ "%.2f"|format(backup.stats.total_size_gb) }}</td>
                        <td>
                            <span class="badge {{ 'text-bg-success' if 'Concluído' in backup.status else 'text-bg-danger' }}">
                                {{ backup.status }}
                            </span>
                        </td>
                    </tr>
                    {% else %}
                    <tr>
                        <td colspan="7" class="text-center">Nenhum backup realizado ainda.</td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Scheduled Tasks -->
<div class="card">
    <div class="card-header">
        <h5 class="card-title mb-0"><i class="bi bi-calendar-check-fill me-2"></i> Backups Agendados</h5>
    </div>
    <div class="card-body">
         <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>Ativo</th>
                        <th>Tipo</th>
                        <th>Frequência</th>
                        <th>Próxima Execução</th>
                    </tr>
                </thead>
                <tbody>
                {% for job in scheduled_jobs %}
                    <tr>
                        <td>
                            <i class="bi {{ 'bi-check-circle-fill text-success' if job.active else 'bi-x-circle-fill text-danger' }}"></i>
                        </td>
                        <td>{{ job.type }}</td>
                        <td>A cada {{ job.interval }} {{ job.period }}(s)</td>
                        <td>{{ job.next_run }}</td>
                    </tr>
                {% else %}
                    <tr>
                        <td colspan="4" class="text-center">Nenhuma tarefa agendada.</td>
                    </tr>
                {% endfor %}
                </tbody>
            </table>
         </div>
    </div>
</div>
{% endblock %}

{% block scripts %}
const progressToastEl = document.getElementById('progressToast');
const progressToast = new bootstrap.Toast(progressToastEl);
const progressBar = document.getElementById('progressBar');
const toastMessage = document.getElementById('toast-message');
const toastDetails = document.getElementById('toast-details');

function runBackup(type) {
    fetch('/run_backup/' + type, { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if(data.status === 'error') {
                alert('Erro: ' + data.message);
            } else {
                console.log(data.message);
                checkStatus();
            }
        });
}

function checkStatus() {
    fetch('/api/status')
        .then(response => response.json())
        .then(data => {
            if (data.running) {
                progressToast.show();
                const progress = data.progress.toFixed(2);
                progressBar.style.width = progress + '%';
                progressBar.innerText = progress + '%';
                progressBar.setAttribute('aria-valuenow', progress);

                let message = `Backup <strong>${data.task_id}</strong> em andamento...`;
                if(data.messages && data.messages.length > 0){
                    message = data.messages[data.messages.length - 1];
                }
                toastMessage.innerHTML = message;

                toastDetails.innerText = `Arquivo: ${data.current_file || 'N/A'} (${data.processed_files}/${data.total_files})`;

                setTimeout(checkStatus, 1000); // Poll every second
            } else {
                 // Wait a moment for the final state to be written, then hide and reload.
                setTimeout(() => {
                    progressToast.hide();
                    if (window.location.pathname === '/') {
                       location.reload();
                    }
                }, 2000);
            }
        });
}

// Initial check on page load
document.addEventListener('DOMContentLoaded', function() {
    checkStatus();
});
{% endblock %}
"""

SETTINGS_TEMPLATE = """
{% extends "layout.html" %}
{% block title %}Configurações{% endblock %}
{% block content %}
<h1 class="mb-4">Configurações</h1>

<form method="post">
    <div class="card mb-4">
        <div class="card-header">
            <h5 class="card-title mb-0"><i class="bi bi-folder-fill me-2"></i> Caminhos de Backup</h5>
        </div>
        <div class="card-body">
            <div class="mb-3">
                <label for="source_dir" class="form-label">Local de Origem</label>
                <input type="text" class="form-control" id="source_dir" name="source_dir" value="{{ config.source_dir }}">
            </div>
            <div class="mb-3">
                <label for="dest_full" class="form-label">Destino Completo</label>
                <input type="text" class="form-control" id="dest_full" name="dest_full" value="{{ config.dest_paths.Completo }}">
            </div>
            <div class="mb-3">
                <label for="dest_diff" class="form-label">Destino Diferencial</label>
                <input type="text" class="form-control" id="dest_diff" name="dest_diff" value="{{ config.dest_paths.Diferencial }}">
            </div>
            <div class="mb-3">
                <label for="dest_inc" class="form-label">Destino Incremental</label>
                <input type="text" class="form-control" id="dest_inc" name="dest_inc" value="{{ config.dest_paths.Incremental }}">
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="card-title mb-0"><i class="bi bi-clock-fill me-2"></i> Agendador de Tarefas</h5>
            <button type="button" class="btn btn-sm btn-success" id="add-schedule"><i class="bi bi-plus-circle me-1"></i> Adicionar Tarefa</button>
        </div>
        <div class="card-body" id="schedules-container">
            {% for schedule in config.schedules %}
            <div class="schedule-item border p-3 mb-3 rounded">
                <button type="button" class="btn-close float-end" aria-label="Close" onclick="this.parentElement.remove()"></button>
                <div class="row">
                    <div class="col-md-3 mb-2">
                        <label class="form-label">Tipo</label>
                        <select name="schedule_type" class="form-select">
                            <option value="Completo" {{ 'selected' if schedule.type == 'Completo' }}>Completo</option>
                            <option value="Diferencial" {{ 'selected' if schedule.type == 'Diferencial' }}>Diferencial</option>
                            <option value="Incremental" {{ 'selected' if schedule.type == 'Incremental' }}>Incremental</option>
                        </select>
                    </div>
                     <div class="col-md-3 mb-2">
                        <label class="form-label">Frequência</label>
                        <input type="number" name="schedule_interval" class="form-control" value="{{ schedule.interval }}" min="1">
                    </div>
                    <div class="col-md-3 mb-2">
                         <label class="form-label">Período</label>
                        <select name="schedule_period" class="form-select">
                            <option value="minutes" {{ 'selected' if schedule.period == 'minutes' }}>Minutos</option>
                            <option value="hours" {{ 'selected' if schedule.period == 'hours' }}>Horas</option>
                            <option value="days" {{ 'selected' if schedule.period == 'days' }}>Dias</option>
                        </select>
                    </div>
                     <div class="col-md-3 mb-2 d-flex align-items-end">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" role="switch" name="schedule_active_{{ loop.index0 }}" value="true" {{ 'checked' if schedule.active }}>
                            <label class="form-check-label">Ativo</label>
                        </div>
                    </div>
                </div>
                 <div class="row">
                    <div class="col-md-4">
                        <label class="form-label">Retenção</label>
                        <input type="number" name="schedule_retention_value" class="form-control" value="{{ schedule.retention_value }}" min="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Unidade de Retenção</label>
                        <select name="schedule_retention_unit" class="form-select">
                            <option value="days" {{ 'selected' if schedule.retention_unit == 'days' }}>Dias</option>
                            <option value="versions" {{ 'selected' if schedule.retention_unit == 'versions' }}>Versões</option>
                        </select>
                    </div>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>

    <button type="submit" class="btn btn-primary mt-4"><i class="bi bi-save-fill me-1"></i> Salvar Configurações</button>
</form>

<div id="schedule-template" style="display: none;">
    <div class="schedule-item border p-3 mb-3 rounded">
        <button type="button" class="btn-close float-end" aria-label="Close" onclick="this.parentElement.remove()"></button>
        <div class="row">
            <div class="col-md-3 mb-2">
                <label class="form-label">Tipo</label>
                <select name="schedule_type" class="form-select">
                    <option value="Completo">Completo</option>
                    <option value="Diferencial">Diferencial</option>
                    <option value="Incremental" selected>Incremental</option>
                </select>
            </div>
             <div class="col-md-3 mb-2">
                <label class="form-label">Frequência</label>
                <input type="number" name="schedule_interval" class="form-control" value="1" min="1">
            </div>
            <div class="col-md-3 mb-2">
                 <label class="form-label">Período</label>
                <select name="schedule_period" class="form-select">
                    <option value="minutes">Minutos</option>
                    <option value="hours">Horas</option>
                    <option value="days" selected>Dias</option>
                </select>
            </div>
             <div class="col-md-3 mb-2 d-flex align-items-end">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" role="switch" name="schedule_active" value="true" checked>
                    <label class="form-check-label">Ativo</label>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-4">
                <label class="form-label">Retenção</label>
                <input type="number" name="schedule_retention_value" class="form-control" value="30" min="0">
            </div>
            <div class="col-md-4">
                <label class="form-label">Unidade de Retenção</label>
                <select name="schedule_retention_unit" class="form-select">
                    <option value="days" selected>Dias</option>
                    <option value="versions">Versões</option>
                </select>
            </div>
        </div>
    </div>
</div>
{% endblock %}

{% block scripts %}
document.getElementById('add-schedule').addEventListener('click', function() {
    const template = document.getElementById('schedule-template');
    const clone = template.firstElementChild.cloneNode(true);
    const newIndex = document.querySelectorAll('.schedule-item').length;

    // Update name for the active checkbox to be unique
    const activeCheckbox = clone.querySelector('input[name="schedule_active"]');
    if (activeCheckbox) {
        activeCheckbox.name = `schedule_active_${newIndex}`;
    }

    document.getElementById('schedules-container').appendChild(clone);
});
{% endblock %}
"""

LOGS_TEMPLATE = """
{% extends "layout.html" %}
{% block title %}Logs e Relatórios{% endblock %}
{% block content %}
<h1 class="mb-4">Logs e Relatórios</h1>

<div class="card">
    <div class="card-header">
        <h5 class="card-title mb-0"><i class="bi bi-file-earmark-text-fill me-2"></i> Conteúdo do Log do Sistema</h5>
    </div>
    <div class="card-body">
        <pre class="bg-dark text-white p-3 rounded" style="max-height: 600px; overflow-y: auto;"><code>{{ log_content }}</code></pre>
    </div>
</div>
{% endblock %}
"""

RESTORE_TEMPLATE = """
{% extends "layout.html" %}
{% block title %}Restaurar Backup{% endblock %}
{% block content %}
<h1 class="mb-4">Restaurar Backup</h1>

{% with messages = get_flashed_messages(with_categories=true) %}
  {% if messages %}
    {% for category, message in messages %}
      <div class="alert alert-{{ category }} alert-dismissible fade show" role="alert">
        {{ message }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    {% endfor %}
  {% endif %}
{% endwith %}

<div class="card">
    <div class="card-header">
        <h5 class="card-title mb-0">Explorador de Arquivos</h5>
    </div>
    <div class="card-body">
        <p>Navegando no backup: <strong>{{ backup.id }}</strong></p>
        <p>Selecione os itens para restaurar para: <strong>{{ source_dir }}</strong></p>
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ url_for('restore_explorer', backup_id=backup.id) }}">Raiz</a></li>
                {% for part, path in breadcrumbs.items() %}
                <li class="breadcrumb-item"><a href="{{ url_for('restore_explorer', backup_id=backup.id, subpath=path) }}">{{ part }}</a></li>
                {% endfor %}
            </ol>
        </nav>

        <form id="restore-form" method="post" action="{{ url_for('restore_files', backup_id=backup.id) }}">
            <div class="d-flex justify-content-end mb-3">
                <button type="submit" class="btn btn-success"><i class="bi bi-download me-2"></i>Restaurar Selecionados</button>
            </div>

            <div class="list-group">
                <div class="list-group-item bg-dark">
                    <input class="form-check-input me-1" type="checkbox" id="select-all">
                    <label class="form-check-label" for="select-all">Selecionar Tudo</label>
                </div>
                {% for item in contents %}
                    <div class="list-group-item">
                       <input class="form-check-input me-1 item-checkbox" type="checkbox" name="selected_items" value="{{ item.path }}" id="item-{{ loop.index }}">
                       {% if item.type == 'dir' %}
                            <i class="bi bi-folder-fill me-2 text-warning"></i>
                            <a href="{{ url_for('restore_explorer', backup_id=backup.id, subpath=item.path) }}" class="text-decoration-none">{{ item.name }}</a>
                       {% else %}
                            <i class="bi bi-file-earmark-text me-2"></i>
                            <label class="form-check-label" for="item-{{ loop.index }}">{{ item.name }}</label>
                       {% endif %}
                    </div>
                {% else %}
                    <div class="list-group-item">Este diretório está vazio.</div>
                {% endfor %}
            </div>
        </form>
    </div>
</div>
{% endblock %}

{% block scripts %}
document.getElementById('select-all').addEventListener('change', function(e) {
    document.querySelectorAll('.item-checkbox').forEach(function(checkbox) {
        checkbox.checked = e.target.checked;
    });
});
{% endblock %}
"""

# --- Funções de Gerenciamento ---

def load_config():
    if not os.path.exists(CONFIG_FILE):
        default_config = {
            "source_dir": os.path.join(DATA_DIR, 'origem'),
            "dest_paths": {
                "Completo": os.path.join(DATA_DIR, 'destino', 'Completo'),
                "Diferencial": os.path.join(DATA_DIR, 'destino', 'Diferencial'),
                "Incremental": os.path.join(DATA_DIR, 'destino', 'Incremental'),
            },
            "schedules": [],
            "users": {
                "admin": generate_password_hash("admin")
            }
        }
        save_config(default_config)
        return default_config
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)

def load_db():
    if not os.path.exists(DB_FILE):
        db = {"backups": []}
        save_db(db)
        return db
    try:
        with open(DB_FILE, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return {"backups": []}

def save_db(db):
    with open(DB_FILE, 'w') as f:
        json.dump(db, f, indent=4)

def get_disk_usage(path):
    try:
        usage = psutil.disk_usage(path)
        return {
            "path": path,
            "total": usage.total / (1024**3),
            "used": usage.used / (1024**3),
            "free": usage.free / (1024**3),
            "percent": usage.percent
        }
    except FileNotFoundError:
        return { "path": path, "total": 0, "used": 0, "free": 0, "percent": 0 }

# --- SETUP JINJA LOADER FOR STRING TEMPLATES ---
app.jinja_loader = DictLoader({
    'layout.html': LAYOUT_TEMPLATE,
    'index.html': INDEX_TEMPLATE,
    'settings.html': SETTINGS_TEMPLATE,
    'logs.html': LOGS_TEMPLATE,
    'restore.html': RESTORE_TEMPLATE
})

# --- Classe Principal de Backup ---
class BackupManager:
    def __init__(self):
        self.config = load_config()

    def _update_status(self, progress=None, current_file=None, message=None, inc_processed=False):
        with backup_status_lock:
            if progress is not None:
                backup_status['progress'] = progress
            if current_file is not None:
                backup_status['current_file'] = current_file
            if message is not None:
                backup_status['messages'].append(f"[{datetime.now().strftime('%H:%M:%S')}] {message}")
                logging.info(f"[{backup_status['task_id']}] {message}")
            if inc_processed:
                backup_status['processed_files'] += 1
            if backup_status['total_files'] > 0:
                 backup_status['progress'] = (backup_status['processed_files'] / backup_status['total_files']) * 100

    def _hash_file(self, filepath):
        hasher = hashlib.sha256()
        try:
            with open(filepath, 'rb') as f:
                while chunk := f.read(8192):
                    hasher.update(chunk)
            return hasher.hexdigest()
        except (IOError, OSError) as e:
            self._update_status(message=f"ERRO: Não foi possível ler o hash de {filepath}: {e}")
            return None

    def _get_last_backup(self, of_type=None):
        db = load_db()
        backups = sorted(
            [b for b in db['backups'] if b['status'] == 'Concluído' and (of_type is None or b['type'] == of_type)],
            key=lambda x: x['end_time'],
            reverse=True
        )
        return backups[0] if backups else None

    def _build_file_map(self, backup_record):
        manifest_path = os.path.join(backup_record['path'], 'manifest.json')
        if not os.path.exists(manifest_path):
            return {}
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)

        file_map = {}
        for item in manifest:
            # Store full path to the backed up file for hardlinking
            item['full_backup_path'] = os.path.join(backup_record['path'], item['relative_path'])
            file_map[item['relative_path']] = item
        return file_map

    def apply_retention_policy(self, backup_type, retention_value, retention_unit):
        if retention_value <= 0:
            return

        self._update_status(message=f"Aplicando política de retenção para '{backup_type}': manter os últimos {retention_value} {retention_unit}.")
        db = load_db()
        now = datetime.now()

        all_other_backups = [b for b in db['backups'] if b['type'] != backup_type]
        backups_of_type = sorted(
            [b for b in db['backups'] if b['type'] == backup_type],
            key=lambda x: x['end_time'],
            reverse=True
        )

        retained_backups = []
        backups_to_delete = []

        if retention_unit == 'days':
            for backup in backups_of_type:
                backup_date = datetime.strptime(backup['end_time'], '%Y-%m-%d %H:%M:%S')
                if now - backup_date > timedelta(days=retention_value):
                    backups_to_delete.append(backup)
                else:
                    retained_backups.append(backup)

        elif retention_unit == 'versions':
            retained_backups = backups_of_type[:retention_value]
            backups_to_delete = backups_of_type[retention_value:]

        deleted_count = 0
        for backup in backups_to_delete:
            try:
                self._update_status(message=f"Excluindo backup antigo: {backup['path']}")
                shutil.rmtree(backup['path'])
                deleted_count += 1
            except FileNotFoundError:
                self._update_status(message=f"AVISO: Diretório de backup não encontrado para exclusão: {backup['path']}")
            except Exception as e:
                self._update_status(message=f"ERRO ao excluir {backup['path']}: {e}")

        if deleted_count > 0:
            db['backups'] = all_other_backups + retained_backups
            save_db(db)
            self._update_status(message=f"Política de retenção concluída. {deleted_count} backups antigos foram excluídos.")

    def run_backup(self, backup_type, retention_value=30, retention_unit='days'):
        with backup_status_lock:
            if backup_status['running']:
                logging.warning("Tentativa de iniciar um novo backup enquanto outro já está em execução.")
                return

            # Reset status
            backup_status['running'] = True
            backup_status['progress'] = 0
            backup_status['total_files'] = 0
            backup_status['processed_files'] = 0
            backup_status['current_file'] = ''
            backup_status['start_time'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            backup_status['task_id'] = f"{backup_type}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            backup_status['messages'] = []

        try:
            self.config = load_config()
            source_dir = self.config['source_dir']
            dest_dir_base = self.config['dest_paths'][backup_type]

            if not os.path.isdir(source_dir):
                raise FileNotFoundError(f"Diretório de origem não encontrado: {source_dir}")

            timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
            dest_dir = os.path.join(dest_dir_base, timestamp)
            os.makedirs(dest_dir, exist_ok=True)

            self._update_status(message=f"Iniciando backup '{backup_type}' de '{source_dir}' para '{dest_dir}'")

            # Initialize stats
            stats = {
                'total_files': 0,
                'files_copied': 0,
                'hardlinks_created': 0,
                'skipped_files': 0,
                'total_size_bytes': 0,
                'errors': 0
            }
            manifest = []

            # Determine reference backup and build its file map
            ref_map = {}
            if backup_type == 'Incremental':
                ref_backup = self._get_last_backup() # Last of any type
                if ref_backup:
                    self._update_status(message=f"Baseando-se no último backup: {ref_backup['path']}")
                    ref_map = self._build_file_map(ref_backup)
            elif backup_type == 'Diferencial':
                ref_backup = self._get_last_backup(of_type='Completo') # Last full
                if ref_backup:
                    self._update_status(message=f"Baseando-se no último backup completo: {ref_backup['path']}")
                    ref_map = self._build_file_map(ref_backup)

            # Phase 1: Count total files
            total_files = sum(len(files) for _, _, files in os.walk(source_dir))
            with backup_status_lock:
                 backup_status['total_files'] = total_files

            # Phase 2: Process files
            for root, _, files in os.walk(source_dir):
                for filename in files:
                    source_path = os.path.join(root, filename)
                    relative_path = os.path.relpath(source_path, source_dir)
                    dest_path = os.path.join(dest_dir, relative_path)

                    self._update_status(current_file=relative_path)
                    stats['total_files'] += 1

                    try:
                        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                        current_hash = self._hash_file(source_path)
                        if not current_hash:
                            stats['skipped_files'] += 1
                            stats['errors'] += 1
                            continue

                        file_size = os.path.getsize(source_path)
                        ref_file_info = ref_map.get(relative_path)

                        action_taken = None

                        if ref_file_info:
                            if ref_file_info['hash'] == current_hash:
                                try:
                                    os.link(ref_file_info['full_backup_path'], dest_path)
                                    stats['hardlinks_created'] += 1
                                    action_taken = 'hardlink'
                                except Exception as e:
                                    self._update_status(message=f"AVISO: Falha ao criar hardlink para {relative_path}, copiando o arquivo. Erro: {e}")
                                    shutil.copy2(source_path, dest_path)
                                    stats['files_copied'] += 1
                                    action_taken = 'copy'
                            else:
                                shutil.copy2(source_path, dest_path)
                                stats['files_copied'] += 1
                                action_taken = 'copy'
                        else:
                            shutil.copy2(source_path, dest_path)
                            stats['files_copied'] += 1
                            action_taken = 'copy'

                        if action_taken:
                           stats['total_size_bytes'] += file_size
                           manifest.append({
                               'relative_path': relative_path,
                               'hash': current_hash,
                               'size': file_size,
                               'action': action_taken
                           })

                    except (IOError, OSError) as e:
                        self._update_status(message=f"ERRO: Pulando arquivo {source_path}: {e}")
                        stats['skipped_files'] += 1
                        stats['errors'] += 1
                    finally:
                        self._update_status(inc_processed=True)

            with open(os.path.join(dest_dir, 'manifest.json'), 'w') as f:
                json.dump(manifest, f, indent=2)

            db = load_db()
            stats['total_size_gb'] = stats['total_size_bytes'] / (1024**3)
            backup_record = {
                'id': backup_status['task_id'],
                'start_time': backup_status['start_time'],
                'end_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'type': backup_type,
                'path': dest_dir,
                'status': 'Concluído' if stats['errors'] == 0 else 'Concluído com erros',
                'stats': stats
            }
            db['backups'].append(backup_record)
            save_db(db)

            self._update_status(message=f"Backup concluído. Copiados: {stats['files_copied']}, Links: {stats['hardlinks_created']}, Erros: {stats['errors']}.")

            self.apply_retention_policy(backup_type, retention_value, retention_unit)

        except Exception as e:
            logging.error(f"Falha crítica no backup: {e}", exc_info=True)
            self._update_status(message=f"FALHA CRÍTICA: {e}")
        finally:
            with backup_status_lock:
                backup_status['running'] = False
                backup_status['progress'] = 100

# --- Instâncias e Scheduler ---
backup_manager = BackupManager()
scheduler = BackgroundScheduler(daemon=True)

def schedule_backup_job(schedule_config):
    job_id = f"backup_{schedule_config['type']}_{schedule_config['interval']}_{schedule_config['period']}"
    logging.info(f"Executando tarefa agendada: {job_id}")
    backup_manager.run_backup(
        schedule_config['type'],
        schedule_config.get('retention_value', 30),
        schedule_config.get('retention_unit', 'days')
    )

def reload_scheduler():
    scheduler.remove_all_jobs()
    config = load_config()
    for schedule in config.get('schedules', []):
        if schedule.get('active', False):
            job_id = f"backup_{schedule['type']}_{schedule['interval']}_{schedule['period']}"
            scheduler.add_job(
                schedule_backup_job,
                'interval',
                **{schedule['period']: schedule['interval']},
                id=job_id,
                replace_existing=True,
                args=[schedule]
            )
            logging.info(f"Tarefa '{job_id}' agendada para cada {schedule['interval']} {schedule['period']}.")

# --- Rotas da Aplicação Flask ---
@app.before_request
def check_login():
    if request.endpoint not in ['login', 'static'] and 'username' not in session:
        return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        config = load_config()
        user_hash = config['users'].get(username)
        if user_hash and check_password_hash(user_hash, password):
            session['username'] = username
            return redirect(url_for('index'))
        return render_template_string(LOGIN_TEMPLATE, error="Usuário ou senha inválidos")
    return render_template_string(LOGIN_TEMPLATE)

@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))

@app.route('/')
def index():
    config = load_config()
    db = load_db()

    disk_usage = {
        "Completo": get_disk_usage(config['dest_paths']['Completo']),
        "Diferencial": get_disk_usage(config['dest_paths']['Diferencial']),
        "Incremental": get_disk_usage(config['dest_paths']['Incremental'])
    }

    backups = sorted(db['backups'], key=lambda x: x['end_time'], reverse=True)[:5]

    scheduled_jobs = []
    for job in scheduler.get_jobs():
        parts = job.id.split('_')
        if len(parts) >= 4:
            scheduled_jobs.append({
                'active': True,
                'type': parts[1],
                'interval': parts[2],
                'period': parts[3],
                'next_run': job.next_run_time.strftime('%Y-%m-%d %H:%M:%S') if job.next_run_time else 'N/A'
            })

    return render_template('index.html',
        disk_usage=disk_usage,
        backups=backups,
        scheduled_jobs=scheduled_jobs)

@app.route('/settings', methods=['GET', 'POST'])
def settings():
    if request.method == 'POST':
        config = load_config()
        config['source_dir'] = request.form['source_dir']
        config['dest_paths']['Completo'] = request.form['dest_full']
        config['dest_paths']['Diferencial'] = request.form['dest_diff']
        config['dest_paths']['Incremental'] = request.form['dest_inc']

        config['schedules'] = []
        types = request.form.getlist('schedule_type')
        intervals = request.form.getlist('schedule_interval')
        periods = request.form.getlist('schedule_period')
        retention_values = request.form.getlist('schedule_retention_value')
        retention_units = request.form.getlist('schedule_retention_unit')

        active_checkboxes = {k:v for k,v in request.form.items() if k.startswith('schedule_active_')}

        for i in range(len(types)):
            is_active = active_checkboxes.get(f'schedule_active_{i}') == 'true'
            config['schedules'].append({
                'type': types[i],
                'interval': int(intervals[i]),
                'period': periods[i],
                'retention_value': int(retention_values[i]),
                'retention_unit': retention_units[i],
                'active': is_active
            })

        save_config(config)
        reload_scheduler()
        return redirect(url_for('settings'))

    config = load_config()
    return render_template('settings.html', config=config)

@app.route('/logs')
def logs():
    try:
        with open(LOG_FILE, 'r') as f:
            log_content = f.read()
    except FileNotFoundError:
        log_content = "Arquivo de log não encontrado."
    return render_template('logs.html', log_content=log_content)

@app.route('/restore/<backup_id>')
@app.route('/restore/<backup_id>/<path:subpath>')
def restore_explorer(backup_id, subpath=''):
    db = load_db()
    config = load_config()
    backup = next((b for b in db['backups'] if b['id'] == backup_id), None)
    if not backup:
        abort(404, description="Backup não encontrado")

    base_path = os.path.realpath(backup['path'])
    current_path = os.path.join(base_path, subpath)

    # Security check: Prevent directory traversal
    if not os.path.realpath(current_path).startswith(base_path):
        abort(403, description="Acesso negado")

    contents = []
    try:
        # Sort contents to show directories first
        dir_contents = sorted(os.listdir(current_path))
        for item in dir_contents:
            item_path = os.path.join(current_path, item)
            relative_item_path = os.path.relpath(item_path, base_path)
            if os.path.isdir(item_path):
                contents.append({'name': item, 'type': 'dir', 'path': relative_item_path})
        for item in dir_contents:
            item_path = os.path.join(current_path, item)
            relative_item_path = os.path.relpath(item_path, base_path)
            if os.path.isfile(item_path):
                contents.append({'name': item, 'type': 'file', 'path': relative_item_path})

    except FileNotFoundError:
        abort(404, description="Caminho não encontrado no backup")

    breadcrumbs = {}
    if subpath:
        parts = subpath.split(os.sep)
        for i in range(len(parts)):
            breadcrumbs[parts[i]] = os.sep.join(parts[:i+1])

    return render_template('restore.html',
        backup=backup,
        contents=contents,
        breadcrumbs=breadcrumbs,
        source_dir=config['source_dir'])

@app.route('/restore_files/<backup_id>', methods=['POST'])
def restore_files(backup_id):
    selected_items = request.form.getlist('selected_items')
    if not selected_items:
        flash('Nenhum item selecionado para restaurar.', 'warning')
        return redirect(url_for('restore_explorer', backup_id=backup_id))

    db = load_db()
    config = load_config()
    backup = next((b for b in db['backups'] if b['id'] == backup_id), None)
    if not backup:
        abort(404, description="Backup não encontrado")

    source_backup_dir = os.path.realpath(backup['path'])
    dest_restore_dir = os.path.realpath(config['source_dir'])

    restored_count = 0
    error_count = 0

    for item_rel_path in selected_items:
        source_path = os.path.join(source_backup_dir, item_rel_path)
        dest_path = os.path.join(dest_restore_dir, item_rel_path)

        # Security check
        if not os.path.realpath(source_path).startswith(source_backup_dir):
            logging.warning(f"Tentativa de travessia de diretório evitada em restauração: {item_rel_path}")
            error_count += 1
            continue

        try:
            # Ensure parent directory of destination exists
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)

            if os.path.isdir(source_path):
                shutil.copytree(source_path, dest_path, dirs_exist_ok=True)
                logging.info(f"Restaurado diretório: '{source_path}' para '{dest_path}'")
            elif os.path.isfile(source_path):
                shutil.copy2(source_path, dest_path)
                logging.info(f"Restaurado arquivo: '{source_path}' para '{dest_path}'")
            restored_count += 1
        except Exception as e:
            logging.error(f"Erro ao restaurar '{item_rel_path}': {e}", exc_info=True)
            error_count += 1

    if error_count > 0:
        flash(f'{restored_count} itens restaurados com sucesso. Falha ao restaurar {error_count} itens. Verifique os logs.', 'danger')
    else:
        flash(f'{restored_count} itens restaurados com sucesso!', 'success')

    return redirect(request.referrer or url_for('restore_explorer', backup_id=backup_id))


@app.route('/run_backup/<backup_type>', methods=['POST'])
def run_backup_route(backup_type):
    if backup_type not in ['Completo', 'Diferencial', 'Incremental']:
        return jsonify({'status': 'error', 'message': 'Tipo de backup inválido.'}), 400

    with backup_status_lock:
        if backup_status['running']:
            return jsonify({'status': 'error', 'message': 'Um backup já está em execução.'}), 409

    thread = Thread(target=backup_manager.run_backup, args=(backup_type, 30, 'days'))
    thread.daemon = True
    thread.start()

    return jsonify({'status': 'ok', 'message': f'Backup {backup_type} iniciado.'})

@app.route('/api/status')
def api_status():
    with backup_status_lock:
        return jsonify(backup_status)

# --- Inicialização ---
if __name__ == '__main__':
    os.makedirs(BASE_DIR, exist_ok=True)
    load_config()
    load_db()

    reload_scheduler()
    scheduler.start()

    logging.info("Iniciando a aplicação BackuPY.")
    app.run(host='0.0.0.0', port=5000, debug=False)

