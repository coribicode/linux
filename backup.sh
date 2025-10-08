sudo apt update
sudo apt install python3-flask -y

mkdir -p /webbkp
mkdir -p /webbkp/BACKUP
mkdir -p /webbkp/data
mkdir -p /webbkp/static
mkdir -p /webbkp/templates

cat << 'EOF' > /webbkp/app.py
import os, shutil, datetime, threading, json
from flask import Flask, render_template, request, redirect, url_for, session, jsonify

app = Flask(__name__)
app.secret_key = "supersecretkey"

# Configurações
BACKUP_DIR = "/webbkp/BACKUP"
DATA_DIR = "/webbkp/data"
MAX_SIZE_GB = 10
USERNAME = "admin"
PASSWORD = "1234"

# Progressos globais
progress = {"backup":0,"restore":0,"file":""}
log_backup=[]
log_restore=[]

# ---------- FUNÇÕES AUXILIARES -----------
def sizeof_gb(path):
    total = 0
    for dp, dirs, files in os.walk(path):
        for f in files:
            total += os.path.getsize(os.path.join(dp,f))
    return round(total/(1024**3),2)

def cleanup_backups():
    backups = sorted([os.path.join(BACKUP_DIR,f) for f in os.listdir(BACKUP_DIR)], key=os.path.getmtime)
    total = sizeof_gb(BACKUP_DIR)
    while total>MAX_SIZE_GB and len(backups)>5:
        shutil.rmtree(backups[0])
        backups.pop(0)
        total = sizeof_gb(BACKUP_DIR)

def copy_backup(src,dst,log_list,prog_dict):
    total_files = sum([len(files) for r,d,files in os.walk(src)])
    count = 0
    for dp, dirs, files in os.walk(src):
        rel = os.path.relpath(dp,src)
        dst_dir = os.path.join(dst,rel)
        os.makedirs(dst_dir,exist_ok=True)
        for f in files:
            src_file = os.path.join(dp,f)
            dst_file = os.path.join(dst_dir,f)
            shutil.copy2(src_file,dst_file)
            count +=1
            prog_dict["backup"] = int(count*100/total_files)
            prog_dict["file"] = f
            log_list.append({"name":os.path.relpath(dst_file,dst),"is_image":f.split('.')[-1].lower() in ["jpg","jpeg","png"]})

def restore_path(src,dst,log_list,prog_dict):
    """Restaura um arquivo ou pasta, atualizando o progress"""
    if os.path.isdir(src):
        total_files = sum([len(files) for r,d,files in os.walk(src)])
        count = 0
        for dp, dirs, files in os.walk(src):
            rel = os.path.relpath(dp,src)
            dst_dir = os.path.join(dst,rel)
            os.makedirs(dst_dir,exist_ok=True)
            for f in files:
                shutil.copy2(os.path.join(dp,f), os.path.join(dst_dir,f))
                count +=1
                prog_dict["restore"] = int(count*100/total_files)
                prog_dict["file"] = f
                log_list.append({"name":os.path.join(rel,f),"is_image":f.split('.')[-1].lower() in ["jpg","jpeg","png"]})
    else:
        os.makedirs(os.path.dirname(dst),exist_ok=True)
        shutil.copy2(src,dst)
        prog_dict["restore"] = 100
        prog_dict["file"] = os.path.basename(src)
        log_list.append({"name":os.path.basename(src),"is_image":src.split('.')[-1].lower() in ["jpg","jpeg","png"]})

# ---------- ROTAS -----------

@app.route("/", methods=["GET","POST"])
def login():
    session.pop("user", None)
    if request.method=="POST":
        u = request.form.get("user")
        p = request.form.get("pass")
        if u==USERNAME and p==PASSWORD:
            session["user"]=u
            return redirect(url_for("index"))
    return render_template("login.html")

@app.route("/index")
def index():
    if "user" not in session: return redirect("/")
    os.makedirs(BACKUP_DIR,exist_ok=True)
    backups=[]
    for b in sorted(os.listdir(BACKUP_DIR)):
        path=os.path.join(BACKUP_DIR,b)
        size=sizeof_gb(path)
        backups.append({"name":b,"size_gb":size})
    total_size=sizeof_gb(BACKUP_DIR)
    return render_template("index.html", backups=backups, total_size=total_size)

@app.route("/start_backup")
def start_backup():
    if "user" not in session: return jsonify({"status":"error"})
    timestamp = datetime.datetime.now().strftime("%d-%m-%Y-%H-%M-%S")
    dst = os.path.join(BACKUP_DIR,f"backup-{timestamp}")
    os.makedirs(dst,exist_ok=True)
    global progress, log_backup
    progress={"backup":0,"restore":0,"file":""}
    log_backup=[]
    threading.Thread(target=copy_backup,args=(DATA_DIR,dst,log_backup,progress), daemon=True).start()
    threading.Thread(target=cleanup_backups, daemon=True).start()
    return jsonify({"status":"started"})

@app.route("/progress/<what>")
def get_progress(what):
    if what=="backup":
        return jsonify({"progress":progress["backup"],"file":progress["file"]})
    elif what=="restore":
        return jsonify({"progress":progress["restore"],"file":progress["file"]})
    return jsonify({"progress":0,"file":""})

@app.route("/view/<backup>")
def view_backup(backup):
    if "user" not in session: return redirect("/")
    tree={}
    file_info={}
    backup_path = os.path.join(BACKUP_DIR,backup)
    for dp, dirs, files in os.walk(backup_path):
        rel = os.path.relpath(dp,backup_path)
        dref=tree
        if rel!=".":
            for part in rel.split(os.sep):
                dref=dref.setdefault(part,{})
        for f in files:
            dref[f]={}
            fpath=os.path.join(dp,f)
            size=os.path.getsize(fpath)
            mtime=datetime.datetime.fromtimestamp(os.path.getmtime(fpath)).strftime("%d-%m-%Y %H:%M:%S")
            file_info[os.path.join(rel,f)]={"size":size,"mtime":mtime}
    return render_template("view_backup.html", tree=tree, name_backup=backup, file_info=file_info)

@app.route("/restore_selected/<backup>", methods=["POST"])
def restore_selected(backup):
    if "user" not in session: return jsonify({"status":"error"})
    items = request.json.get("items",[])
    global progress, log_restore
    progress={"backup":0,"restore":0,"file":""}
    log_restore=[]
    backup_path = os.path.join(BACKUP_DIR,backup)

    def task():
        total_items = len(items)
        for idx, item in enumerate(items):
            src = os.path.join(backup_path,item)
            dst = os.path.join(DATA_DIR,item)
            restore_path(src,dst,log_restore,progress)
            progress["restore"] = int(((idx+1)/total_items)*100)
        progress["restore"] = 100
        progress["file"] = ""
    threading.Thread(target=task, daemon=True).start()
    return jsonify({"status":"started"})

@app.route("/delete_selected/<backup>", methods=["POST"])
def delete_selected(backup):
    if "user" not in session: return jsonify({"status":"error"})
    items = request.json.get("items",[])
    backup_path = os.path.join(BACKUP_DIR,backup)
    for item in items:
        path = os.path.join(backup_path,item)
        if os.path.exists(path):
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
    return jsonify({"status":"ok"})

@app.route("/delete_backup/<backup>", methods=["POST"])
def delete_backup(backup):
    if "user" not in session: return jsonify({"status":"error"})
    path=os.path.join(BACKUP_DIR,backup)
    if os.path.exists(path):
        shutil.rmtree(path)
        return jsonify({"status":"ok"})
    return jsonify({"status":"error","msg":"Não encontrado"})

@app.route("/logout")
def logout():
    session.pop("user",None)
    return redirect("/")

if __name__=="__main__":
    os.makedirs(BACKUP_DIR,exist_ok=True)
    os.makedirs(DATA_DIR,exist_ok=True)
    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)
EOF

cat <<'EOF'> /webbkp/static/style.css
body {
  font-family: 'Segoe UI', Tahoma, sans-serif;
}

ul {
  list-style-type: none;
}

button {
  margin-left: 8px;
}

.progress {
  background-color: #e9ecef;
}

.progress-bar {
  transition: width 0.3s ease;
}
EOF

cat <<'EOF'> /webbkp/templates/index.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Sistema de Backup</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="/static/style.css">
<script>
function startBackup(){
    if(confirm("Deseja iniciar o backup agora?")){
        document.getElementById("overlay").style.display="flex";
        fetch("/start_backup").then(r=>r.json()).then(d=>{
            if(d.status==="started"){
                let bar=document.getElementById("backupProgress");
                let interval=setInterval(()=>{
                    fetch("/progress/backup").then(r=>r.json()).then(p=>{
                        bar.style.width=p.progress+"%";
                        bar.innerText=p.progress+"%";
                        if(p.progress>=100){
                            clearInterval(interval);
                            alert("Backup concluído!");
                            location.reload();
                        }
                    });
                },500);
            }
        });
    }
}

function deleteBackup(name){
    if(confirm("Excluir o backup '"+name+"'?")){
        fetch("/delete_backup/"+encodeURIComponent(name), {method:"POST"})
        .then(r=>r.json()).then(d=>{
            if(d.status==="ok"){ location.reload(); }
        });
    }
}
</script>

<style>
#overlay {
  position: fixed;
  top:0; left:0; width:100%; height:100%;
  background: rgba(255,255,255,0.8);
  display: none;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  font-size: 1.5em;
}
.usage-bar {
  height: 25px;
  border-radius: 12px;
  overflow: hidden;
  background-color: #e9ecef;
}
.usage-bar-fill {
  height: 100%;
  text-align: center;
  color: white;
  font-weight: bold;
  line-height: 25px;
}
</style>
</head>
<body class="bg-light">

<div id="overlay">
  <div class="text-center">
    <div class="spinner-border text-primary" style="width: 5rem; height: 5rem;" role="status"></div>
    <p class="mt-3">Executando backup... aguarde</p>
  </div>
</div>

<div class="container py-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>Sistema de Backup</h2>
        <a href="/logout" class="btn btn-outline-danger">Logout</a>
    </div>

    <button class="btn btn-primary mb-3" onclick="startBackup()">Iniciar Backup</button>

    <div class="progress mb-3" style="height:25px;">
        <div id="backupProgress" class="progress-bar progress-bar-striped progress-bar-animated" style="width:0%">0%</div>
    </div>

    <hr>

    <h5>Backups Disponíveis</h5>
    <table class="table table-striped table-bordered mt-3">
        <thead class="table-light">
            <tr>
                <th>Nome</th>
                <th>Tamanho (GB)</th>
                <th>Ações</th>
            </tr>
        </thead>
        <tbody>
            {% for b in backups %}
            <tr>
                <td>{{ b.name }}</td>
                <td>{{ b.size_gb }}</td>
                <td>
                    <a href="/view/{{ b.name }}" class="btn btn-sm btn-outline-primary">Ver</a>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteBackup('{{ b.name }}')">Excluir</button>
                </td>
            </tr>
            {% endfor %}
        </tbody>
    </table>

    <div class="mt-4">
        <h6 class="mb-2">Uso total de armazenamento (limite: 10 GB)</h6>
        {% set percent = (total_size / 10 * 100) | round(1) %}
        <div class="usage-bar">
            <div class="usage-bar-fill {% if percent >= 90 %}bg-danger{% elif percent >= 70 %}bg-warning{% else %}bg-success{% endif %}" style="width: {{ percent }}%;">
                {{ total_size }} GB ({{ percent }}%)
            </div>
        </div>
    </div>
</div>

</body>
</html>

EOF

cat <<'EOF'> /webbkp/templates/login.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Login - Sistema de Backup</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light d-flex align-items-center justify-content-center" style="height:100vh;">
<div class="card shadow p-4" style="width:320px;">
    <h4 class="text-center mb-3">Login</h4>
    <form method="POST">
        <div class="mb-3">
            <label>Usuário</label>
            <input type="text" name="user" class="form-control" required>
        </div>
        <div class="mb-3">
            <label>Senha</label>
            <input type="password" name="pass" class="form-control" required>
        </div>
        <button class="btn btn-primary w-100">Entrar</button>
    </form>
</div>
</body>
</html>
EOF

cat <<'EOF'> /webbkp/templates/view_backup.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Visualizar Backup {{ name_backup }}</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="/static/style.css">
<style>
#overlay {
    position: fixed;
    top:0; left:0; right:0; bottom:0;
    background: rgba(0,0,0,0.5);
    z-index: 9999;
    display: none;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-size: 1.5rem;
    flex-direction: column;
}
</style>
<script>
function toggleFolder(id){
    const el = document.getElementById(id);
    el.style.display = (el.style.display=="none" ? "block" : "none");
}

function showOverlay(msg="Aguardando..."){
    document.getElementById("overlayMessage").innerText = msg;
    document.getElementById("overlay").style.display = "flex";
}

function hideOverlay(){
    document.getElementById("overlay").style.display = "none";
}

// Restaurar itens selecionados
function restoreSelected(){
    const checkboxes = document.querySelectorAll(".file-checkbox:checked");
    const items = Array.from(checkboxes).map(c=>c.value);
    if(items.length==0) { alert("Selecione ao menos um arquivo ou pasta."); return; }

    showOverlay("Restaurando...");

    fetch(`/restore_selected/{{ name_backup }}`,{
        method:"POST",
        headers:{"Content-Type":"application/json"},
        body: JSON.stringify({items})
    }).then(r=>r.json()).then(d=>{
        if(d.status==="started"){
            let interval = setInterval(()=>{
                fetch("/progress/restore").then(r=>r.json()).then(p=>{
                    if(p.progress>=100){
                        clearInterval(interval);
                        setTimeout(()=>{ hideOverlay(); alert("Restauração Concluída!"); location.reload(); }, 1500);
                    }
                });
            },300);
        }
    });
}

// Excluir itens selecionados
function deleteSelected(){
    const checkboxes = document.querySelectorAll(".file-checkbox:checked");
    const items = Array.from(checkboxes).map(c=>c.value);
    if(items.length==0) { alert("Selecione ao menos um arquivo ou pasta."); return; }

    if(confirm("Deseja realmente excluir os itens selecionados?")){
        fetch(`/delete_selected/{{ name_backup }}`,{
            method:"POST",
            headers:{"Content-Type":"application/json"},
            body: JSON.stringify({items})
        }).then(()=>location.reload());
    }
}

// Selecionar todos
function toggleSelectAll(master){
    const checkboxes = document.querySelectorAll(".file-checkbox");
    checkboxes.forEach(c=>c.checked=master.checked);
}

// Selecionar/desmarcar filhos da pasta
function toggleChildCheckboxes(el){
    const li = el.closest("li");
    const checkboxes = li.querySelectorAll("input.file-checkbox");
    checkboxes.forEach(c => c.checked = el.checked);
}

// Marcar pasta pai ao marcar arquivo
function selectParentCheckboxes(el){
    if(!el) return;
    let parentLi = el.closest("ul").closest("li");
    if(parentLi){
        let parentCheckbox = parentLi.querySelector("input.file-checkbox");
        if(parentCheckbox && !parentCheckbox.checked){
            parentCheckbox.checked = true;
            selectParentCheckboxes(parentCheckbox);
        }
    }
}

// Função combinada para filhos e pais
function toggleChildAndParent(el){
    toggleChildCheckboxes(el);
    if(el.checked){
        selectParentCheckboxes(el);
    }
}
</script>
</head>
<body class="bg-light">
<div class="container py-4">
<h2>Backup: {{ name_backup }}</h2>

<!-- Selecionar Todos e Voltar -->
<div class="d-flex justify-content-between align-items-center mb-2">
    <div>
        <label><input type="checkbox" onchange="toggleSelectAll(this)"> Selecionar Todos</label>
    </div>
    <div>
        <a href="/index" class="btn btn-secondary">Voltar</a>
    </div>
</div>

<div class="bg-white border rounded p-3">
    {% macro render_tree(tree, prefix="") %}
        <ul class="list-unstyled ps-3">
        {% for name, subtree in tree.items() %}
            {% set path = prefix + name %}
            {% if '.' in name %}
                <li>
                    <input type="checkbox" class="file-checkbox me-1" value="{{ path }}" onchange="toggleChildAndParent(this)">
                    📄 {{ name }}
                    {% if path in file_info %}
                        <small class="text-muted">({{ (file_info[path].size/1024/1024)|round(2) }} MB - {{ file_info[path].mtime }})</small>
                    {% else %}
                        <small class="text-muted">(Sem informação)</small>
                    {% endif %}
                </li>
            {% else %}
                <li>
                    <input type="checkbox" class="file-checkbox me-1" value="{{ path }}" onchange="toggleChildAndParent(this)">
                    <span style="cursor:pointer;" onclick="toggleFolder('f{{ loop.index0 }}_{{ prefix|replace('/', '_') }}')">📁 <b>{{ name }}</b></span>
                    {% if path in file_info %}
                        <small class="text-muted">({{ (file_info[path].size/1024/1024)|round(2) }} MB - {{ file_info[path].mtime }})</small>
                    {% endif %}
                    <div id="f{{ loop.index0 }}_{{ prefix|replace('/', '_') }}" style="display:none;">
                        {{ render_tree(subtree, path + '/') }}
                    </div>
                </li>
            {% endif %}
        {% endfor %}
        </ul>
    {% endmacro %}

    {{ render_tree(tree) }}
</div>

<!-- Barra de botões -->
<div class="d-flex justify-content-start gap-2 mt-3 p-2 bg-light">
    <button class="btn btn-success" onclick="restoreSelected()">Restaurar Selecionados</button>
    <button class="btn btn-danger" onclick="deleteSelected()">Excluir Selecionados</button>
</div>

</div>

<!-- Overlay para bloqueio e mensagem -->
<div id="overlay">
    <div id="overlayMessage">Restaurando...</div>
</div>

</body>
</html>
EOF

cat <<'EOF'> /etc/systemd/system/webbkp.service
[Unit]
Description=Servidor Flask de Backup Web
After=network.target
Wants=network-online.target

[Service]
User=root
Group=root
WorkingDirectory=/webbkp
ExecStartPre=/bin/sleep 30
ExecStart=/usr/bin/python3 /webbkp/app.py
Restart=always
RestartSec=5
Environment="FLASK_ENV=production"
StandardOutput=append:/var/log/webbkp.log
StandardError=append:/var/log/webbkp_error.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webbkp.service
systemctl start webbkp.service

