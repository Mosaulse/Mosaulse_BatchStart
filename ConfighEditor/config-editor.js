// 配置编辑器核心逻辑 — 简化版（仅 Logging + Applications）
class ConfigEditor {
    constructor() {
        this.apps = [];
        this.logging = {}; // { WriteLog2Log, LogFilePath }
        this.hasChanges = false;
        this.updatePreviewTimeout = null;
        this.init();
    }

    init() {
        this.initTheme();
        this.bindEvents();
        this.loadFromStorage();
        this.render();
        this.updatePreview();
    }

    // ── 事件绑定 ────────────────────────────────────────

    bindEvents() {
        document.getElementById('addAppBtn').addEventListener('click', () => this.addApp());
        document.getElementById('saveBtn').addEventListener('click', () => this.saveToFile());
        document.getElementById('exportBtn').addEventListener('click', () => this.exportConfig());
        document.getElementById('importBtn').addEventListener('click', () => {
            document.getElementById('importFile').click();
        });
        document.getElementById('importFile').addEventListener('change', (e) => this.importConfig(e));
        document.getElementById('copyBtn').addEventListener('click', () => this.copyPreview());

        document.getElementById('themeToggle').addEventListener('click', () => this.toggleTheme());

        document.getElementById('loadIniBtn').addEventListener('click', () => {
            document.getElementById('loadIniFile').click();
        });
        document.getElementById('loadIniFile').addEventListener('change', (e) => this.loadIniFile(e));

        // 日志设置变更
        const grid = document.querySelector('.settings-grid');
        if (grid) {
            grid.addEventListener('input', (e) => {
                if (e.target.matches('input, select')) {
                    this.hasChanges = true;
                    this.updateLogging();
                    this.updatePreview();
                    this.saveToStorage();
                }
            });
        }

        window.addEventListener('beforeunload', () => {
            if (this.hasChanges) this.saveToStorage();
        });
    }

    // ── 本地存储 ────────────────────────────────────────

    loadFromStorage() {
        const saved = localStorage.getItem('batchStartConfig');
        if (saved) {
            try {
                const data = JSON.parse(saved);
                this.apps = data.apps || [];
                this.logging = data.logging || this.getDefaultLogging();
            } catch (e) {
                console.error('加载配置失败:', e);
                this.logging = this.getDefaultLogging();
            }
        } else {
            this.logging = this.getDefaultLogging();
        }
    }

    saveToStorage() {
        localStorage.setItem('batchStartConfig', JSON.stringify({
            apps: this.apps,
            logging: this.logging
        }));
    }

    getDefaultLogging() {
        return {
            WriteLog2Log: 'true',
            LogFilePath: 'BatchStart.log',
            CPUThreshold: 50
        };
    }

    // ── 主题 ────────────────────────────────────────────

    initTheme() {
        const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
        this.applyTheme(prefersDark ? 'dark' : 'light');
        if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                this.applyTheme(e.matches ? 'dark' : 'light');
            });
        }
    }

    toggleTheme() {
        const cur = document.documentElement.getAttribute('data-theme');
        this.applyTheme(cur === 'dark' ? 'light' : 'dark');
    }

    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        const btn = document.getElementById('themeToggle');
        if (btn) btn.textContent = theme === 'dark' ? '🌙' : '☀️';
    }

    // ── 应用 CRUD ───────────────────────────────────────

    addApp() {
        this.apps.push({
            id: Date.now().toString(),
            name: `应用${this.apps.length + 1}`,
            params: [{ id: Date.now().toString() + '_1', value: '' }]
        });
        this.hasChanges = true;
        this.render();
        this.updatePreview();
        this.saveToStorage();
    }

    removeApp(appId) {
        if (confirm('确定要删除此应用吗?')) {
            this.apps = this.apps.filter(a => a.id !== appId);
            this.hasChanges = true;
            this.render();
            this.updatePreview();
            this.saveToStorage();
        }
    }

    addParam(appId) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            app.params.push({ id: Date.now().toString(), value: '' });
            this.hasChanges = true;
            this.render();
            this.updatePreview();
            this.saveToStorage();
        }
    }

    removeParam(appId, paramId) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            app.params = app.params.filter(p => p.id !== paramId);
            this.hasChanges = true;
            this.render();
            this.updatePreview();
            this.saveToStorage();
        }
    }

    updateAppName(appId, value) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            app.name = value;
            this.hasChanges = true;
            this.updatePreview();
            this.saveToStorage();
        }
    }

    updateParamValue(appId, paramId, value) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            const param = app.params.find(p => p.id === paramId);
            if (param) {
                param.value = value;
                this.hasChanges = true;
                this.updatePreview();
                this.saveToStorage();
            }
        }
    }

    // ── 日志设置 ──────────────────────────────────────

    updateLogging() {
        this.logging = {
            WriteLog2Log: document.getElementById('WriteLog2Log').value,
            LogFilePath: document.getElementById('LogFilePath').value,
            CPUThreshold: parseInt(document.getElementById('CPUThreshold').value)
        };
    }

    // ── 路径工具 ───────────────────────────────────────

    quotePath(path) {
        if (!path) return '';
        path = path.trim();
        if (!path) return '';
        path = path.replace(/^["']|["']$/g, '');
        if (path.startsWith('-') || path.startsWith('/')) return path;
        const hasSpecial = /[ \t&|<>^()]/.test(path);
        const isWinPath = /^[a-zA-Z]:\\/i.test(path);
        const isNetPath = /^\\\\/.test(path);
        if (hasSpecial || isWinPath || isNetPath) return `"${path}"`;
        return path;
    }

    // ── 渲染 ───────────────────────────────────────────

    render() {
        // 应用列表
        const container = document.getElementById('appConfig');
        container.innerHTML = this.apps.map(app => `
            <div class="app-item" data-id="${app.id}">
                <div class="app-header">
                    <input type="text"
                           class="app-name-input"
                           value="${this.escapeHtml(app.name)}"
                           placeholder="应用名称"
                           oninput="editor.updateAppName('${app.id}', this.value)">
                    <button class="btn btn-small btn-danger" onclick="editor.removeApp('${app.id}')">删除</button>
                </div>
                <div class="params-container">
                    ${app.params.map(param => `
                        <div class="param-item">
                            <div class="param-header">
                                <span class="param-label">参数</span>
                                <button class="btn btn-small btn-danger" onclick="editor.removeParam('${app.id}', '${param.id}')">✕</button>
                            </div>
                            <input type="text"
                                   class="param-input"
                                   value="${this.escapeHtml(param.value)}"
                                   placeholder="输入参数或路径（自动添加引号）"
                                   oninput="editor.updateParamValue('${app.id}', '${param.id}', this.value)">
                        </div>
                    `).join('')}
                    <button class="btn btn-small btn-secondary" onclick="editor.addParam('${app.id}')">+ 添加参数</button>
                </div>
            </div>
        `).join('');

        // 日志设置
        if (Object.keys(this.logging).length > 0) {
            document.getElementById('WriteLog2Log').value = this.logging.WriteLog2Log;
            document.getElementById('LogFilePath').value = this.logging.LogFilePath;
            document.getElementById('CPUThreshold').value = this.logging.CPUThreshold;
        }
    }

    // ── INI 生成 ───────────────────────────────────────

    generateINI() {
        let ini = '; 批量应用启动配置文件\n';
        ini += '; 注释行以 ; 或 # 开头\n';
        ini += ';\n';
        ini += '; [Logging]      — 日志配置\n';
        ini += '; [Applications] — 要启动的应用列表\n';
        ini += ';\n';
        ini += '; 启动器会根据 CPU 使用率智能调度启动顺序。\n';
        ini += ';\n';
        ini += '; CPUThreshold 为 CPU 使用率阈值（%），低于此值才启动下一个应用\n';
        ini += '; 默认为 50，可通过环境变量 BATCHSTART_CPU_THRESHOLD 覆盖\n';
        ini += '\n';

        ini += '[Logging]\n';
        ini += `; 是否写入日志文件 (true / false)\nWriteLog2Log=${this.logging.WriteLog2Log}\n\n`;
        ini += `; 日志文件路径（相对路径相对于脚本目录，或绝对路径）\nLogFilePath=${this.logging.LogFilePath}\n\n`;
        ini += `; CPU 使用率阈值（%）：低于此值才启动下一个应用\nCPUThreshold=${this.logging.CPUThreshold}\n\n`;

        ini += '[Applications]\n';
        ini += '; 应用名称=完整可执行文件路径 参数1 参数2 ...\n';

        this.apps.forEach(app => {
            const parts = app.params
                .map(p => this.quotePath(p.value))
                .filter(p => p !== '')
                .join(' ');
            ini += parts ? `${app.name}=${parts}\n` : `${app.name}=\n`;
        });

        return ini;
    }

    // ── 预览 ───────────────────────────────────────────

    updatePreview() {
        if (this.updatePreviewTimeout) clearTimeout(this.updatePreviewTimeout);
        this.updatePreviewTimeout = setTimeout(() => {
            this.updateLogging();
            const preview = document.getElementById('preview');
            const content = this.generateINI();
            const highlighted = Prism.highlight(content, Prism.languages.ini, 'ini');
            preview.innerHTML = highlighted;
        }, 50);
    }

    async copyPreview() {
        try {
            await navigator.clipboard.writeText(this.generateINI());
            this.showNotification('已复制到剪贴板!', 'success');
        } catch (e) {
            this.showNotification('复制失败!', 'error');
        }
    }

    // ── 保存 / 导出 / 导入 ─────────────────────────────

    async saveToFile() {
        try {
            const content = this.generateINI();

            if ('showSaveFilePicker' in window) {
                try {
                    const handle = await window.showSaveFilePicker({
                        suggestedName: 'apps.ini',
                        types: [{ description: 'INI 文件', accept: { 'text/plain': ['.ini'] } }]
                    });
                    const writable = await handle.createWritable();
                    await writable.write(content);
                    await writable.close();
                    this.hasChanges = false;
                    this.saveToStorage();
                    this.showNotification('配置已保存到 apps.ini!', 'success');
                    return;
                } catch (e) {
                    if (e.name !== 'AbortError') console.log('降级到下载:', e);
                    else return;
                }
            }

            const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'apps.ini';
            a.click();
            URL.revokeObjectURL(url);
            this.hasChanges = false;
            this.saveToStorage();
            this.showNotification('配置已下载，请替换项目目录中的 apps.ini', 'info');
        } catch (e) {
            console.error('保存失败:', e);
            this.showNotification('保存失败: ' + e.message, 'error');
        }
    }

    exportConfig() {
        const content = JSON.stringify({ apps: this.apps, logging: this.logging }, null, 2);
        const blob = new Blob([content], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'config-export.json';
        a.click();
        URL.revokeObjectURL(url);
        this.showNotification('配置已导出!', 'success');
    }

    importConfig(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const content = e.target.result;
                if (file.name.endsWith('.json')) {
                    const data = JSON.parse(content);
                    this.apps = data.apps || [];
                    this.logging = data.logging || this.getDefaultLogging();
                } else {
                    this.parseINI(content);
                }
                this.hasChanges = false;
                this.render();
                this.updatePreview();
                this.showNotification('配置导入成功!', 'success');
            } catch (error) {
                console.error('导入失败:', error);
                this.showNotification('导入失败: ' + error.message, 'error');
            }
        };
        reader.readAsText(file);
        event.target.value = '';
    }

    loadIniFile(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                this.parseINI(e.target.result);
                this.hasChanges = false;
                this.saveToStorage();
                this.render();
                this.updatePreview();
                this.showNotification('已加载配置文件!', 'success');
            } catch (error) {
                console.error('加载失败:', error);
                this.showNotification('加载失败: ' + error.message, 'error');
            }
        };
        reader.readAsText(file);
        event.target.value = '';
    }

    // ── INI 解析（[Logging] + [Applications]，兼容旧 [app]） ──

    parseINI(content) {
        const lines = content.split('\n');
        let currentSection = null;
        this.apps = [];
        this.logging = this.getDefaultLogging();

        lines.forEach(line => {
            line = line.trim();
            if (!line || line.startsWith(';') || line.startsWith('#')) return;

            if (line.startsWith('[') && line.endsWith(']')) {
                currentSection = line.substring(1, line.length - 1);
                return;
            }

            if (!line.includes('=')) return;
            const [key, value] = line.split('=').map(s => s.trim());

            if (currentSection === 'Applications' || currentSection === 'app') {
                const params = this.parseParams(value);
                this.apps.push({
                    id: Date.now().toString() + '_' + this.apps.length,
                    name: key,
                    params
                });
            } else if (currentSection === 'Logging') {
                if (key === 'WriteLog2Log') this.logging.WriteLog2Log = value;
                else if (key === 'LogFilePath') this.logging.LogFilePath = value;
                else if (key === 'CPUThreshold') this.logging.CPUThreshold = parseInt(value) || 50;
            }
        });
    }

    // ── 参数解析 ───────────────────────────────────────

    parseParams(value) {
        if (!value || value.trim() === '') return [];
        const params = [];
        let current = '';
        let inQuotes = false;
        let i = 0;
        while (i < value.length) {
            const ch = value[i];
            if (ch === '"') { inQuotes = !inQuotes; i++; }
            else if (ch === ' ' && !inQuotes) {
                if (current.trim()) {
                    params.push({ id: Date.now().toString() + '_' + params.length, value: current.trim() });
                    current = '';
                }
                i++;
            } else { current += ch; i++; }
        }
        if (current.trim()) params.push({ id: Date.now().toString() + '_' + params.length, value: current.trim() });
        return params;
    }

    // ── 通知 ───────────────────────────────────────────

    showNotification(message, type = 'info') {
        const el = document.getElementById('notification');
        el.textContent = message;
        el.className = `notification notification-${type}`;
        el.style.display = 'block';
        setTimeout(() => { el.style.display = 'none'; }, 3000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// ── 初始化 ────────────────────────────────────────────────

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => { window.editor = new ConfigEditor(); });
} else {
    window.editor = new ConfigEditor();
}
