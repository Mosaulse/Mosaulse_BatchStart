// 配置编辑器核心逻辑
class ConfigEditor {
    constructor() {
        this.apps = [];
        this.settings = {};
        this.hasChanges = false;
        this.updatePreviewTimeout = null;
        this.init();
    }

    init() {
        this.initTheme();
        this.bindEvents();
        // 从本地存储加载配置
        this.loadFromStorage();
        this.render();
        this.updatePreview();
    }

    // 绑定事件
    bindEvents() {
        document.getElementById('addAppBtn').addEventListener('click', () => this.addApp());
        document.getElementById('saveBtn').addEventListener('click', () => this.saveToFile());
        document.getElementById('exportBtn').addEventListener('click', () => this.exportConfig());
        document.getElementById('importBtn').addEventListener('click', () => {
            document.getElementById('importFile').click();
        });
        document.getElementById('importFile').addEventListener('change', (e) => this.importConfig(e));
        document.getElementById('copyBtn').addEventListener('click', () => this.copyPreview());

        // 主题切换
        document.getElementById('themeToggle').addEventListener('click', () => this.toggleTheme());

        // 加载 apps.ini 文件
        document.getElementById('loadIniBtn').addEventListener('click', () => {
            document.getElementById('loadIniFile').click();
        });
        document.getElementById('loadIniFile').addEventListener('change', (e) => this.loadIniFile(e));



        // 监听设置变更 - 使用事件委托
        const settingsGrid = document.querySelector('.settings-grid');
        if (settingsGrid) {
            settingsGrid.addEventListener('input', (e) => {
                if (e.target.matches('input, select')) {
                    this.hasChanges = true;
                    this.updateSettings();
                    this.updatePreview();
                    // 立即保存到本地存储
                    this.saveToStorage();
                }
            });
        }

        // 自动保存到本地存储
        window.addEventListener('beforeunload', () => {
            if (this.hasChanges) {
                this.saveToStorage();
            }
        });
    }

    // 从本地存储加载
    loadFromStorage() {
        const saved = localStorage.getItem('batchStartConfig');
        if (saved) {
            try {
                const data = JSON.parse(saved);
                this.apps = data.apps || [];
                this.settings = data.settings || this.getDefaultSettings();
            } catch (e) {
                console.error('加载配置失败:', e);
                this.settings = this.getDefaultSettings();
            }
        } else {
            // 没有存储的配置，使用默认设置
            this.settings = this.getDefaultSettings();
        }
    }

    // 保存到本地存储
    saveToStorage() {
        localStorage.setItem('batchStartConfig', JSON.stringify({
            apps: this.apps,
            settings: this.settings
        }));
    }

    // 获取默认设置
    getDefaultSettings() {
        return {
            WriteLog2Log: 'false',
            CPUThreshold: 50,
            MinInterval: 2,
            LogFilePath: 'BatchStart.log',
            MaxWaitTime: 60,
            StartTimeout: 10,
            AppAlreadyRunningAction: 'Skip'
        };
    }

    // 初始化主题
    initTheme() {
        // 1. 检测系统主题
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            this.applyTheme('dark');
        } else {
            this.applyTheme('light');
        }

        // 2. 监听系统主题变化
        if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                this.applyTheme(e.matches ? 'dark' : 'light');
            });
        }
    }

    // 切换主题
    toggleTheme() {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        this.applyTheme(newTheme);
    }

    // 应用主题
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.textContent = theme === 'dark' ? '🌙' : '☀️';
        }
    }

    // 添加应用
    addApp() {
        const id = Date.now().toString();
        this.apps.push({
            id,
            name: `应用${this.apps.length + 1}`,
            params: [
                { id: Date.now().toString() + '_1', value: '' }
            ]
        });
        this.hasChanges = true;
        this.render();
        this.updatePreview();
        // 立即保存到本地存储
        this.saveToStorage();
    }

    // 删除应用
    removeApp(appId) {
        if (confirm('确定要删除此应用吗?')) {
            this.apps = this.apps.filter(app => app.id !== appId);
            this.hasChanges = true;
            this.render();
            this.updatePreview();
            // 立即保存到本地存储
            this.saveToStorage();
        }
    }

    // 添加参数
    addParam(appId) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            app.params.push({
                id: Date.now().toString(),
                value: ''
            });
            this.hasChanges = true;
            this.render();
            this.updatePreview();
            // 立即保存到本地存储
            this.saveToStorage();
        }
    }

    // 删除参数
    removeParam(appId, paramId) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            app.params = app.params.filter(p => p.id !== paramId);
            this.hasChanges = true;
            this.render();
            this.updatePreview();
            // 立即保存到本地存储
            this.saveToStorage();
        }
    }

    // 更新应用名称
    updateAppName(appId, value) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            app.name = value;
            this.hasChanges = true;
            this.updatePreview();
            // 立即保存到本地存储
            this.saveToStorage();
        }
    }

    // 更新参数值
    updateParamValue(appId, paramId, value) {
        const app = this.apps.find(a => a.id === appId);
        if (app) {
            const param = app.params.find(p => p.id === paramId);
            if (param) {
                param.value = value;
                this.hasChanges = true;
                this.updatePreview();
                // 立即保存到本地存储
                this.saveToStorage();
            }
        }
    }

    // 路径自动加引号
    quotePath(path) {
        if (!path) return '';

        // 移除首尾空白
        path = path.trim();

        // 如果为空字符串，返回空
        if (!path) return '';

        // 移除已有的引号（无论是单引号还是双引号）
        path = path.replace(/^["']|["']$/g, '');

        // 如果是纯命令行参数（如 -projectPath, -batchmode 等），不加引号
        if (path.startsWith('-') || path.startsWith('/')) {
            return path;
        }

        // 如果包含空格、特殊字符或反斜杠结尾（Windows路径），则添加引号
        const hasSpecialChars = /[ \t&|<>^()]/.test(path);
        const isWindowsPath = /^[a-zA-Z]:\\/i.test(path);
        const isNetworkPath = /^\\\\/.test(path);

        if (hasSpecialChars || isWindowsPath || isNetworkPath) {
            return `"${path}"`;
        }

        return path;
    }

    // 更新设置
    updateSettings() {
        this.settings = {
            WriteLog2Log: document.getElementById('WriteLog2Log').value,
            CPUThreshold: parseInt(document.getElementById('CPUThreshold').value),
            MinInterval: parseInt(document.getElementById('MinInterval').value),
            LogFilePath: document.getElementById('LogFilePath').value,
            MaxWaitTime: parseInt(document.getElementById('MaxWaitTime').value),
            StartTimeout: parseInt(document.getElementById('StartTimeout').value),
            AppAlreadyRunningAction: document.getElementById('AppAlreadyRunningAction').value
        };
    }

    // 渲染界面
    render() {
        // 渲染应用列表
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

        // 渲染设置
        if (Object.keys(this.settings).length > 0) {
            document.getElementById('WriteLog2Log').value = this.settings.WriteLog2Log;
            document.getElementById('CPUThreshold').value = this.settings.CPUThreshold;
            document.getElementById('MinInterval').value = this.settings.MinInterval;
            document.getElementById('LogFilePath').value = this.settings.LogFilePath;
            document.getElementById('MaxWaitTime').value = this.settings.MaxWaitTime;
            document.getElementById('StartTimeout').value = this.settings.StartTimeout;
            document.getElementById('AppAlreadyRunningAction').value = this.settings.AppAlreadyRunningAction;
        }
    }

    // 生成 INI 配置
    generateINI() {
        let ini = '; 批量应用启动配置文件\n';
        ini += '; 注释行以;或#开头\n';
        ini += '; 路径会自动添加双引号以处理空格\n';
        ini += '; 例子1:\n';
        ini += '; Unity="D:\Unity\Unity 2022.3.62f1\Editor\Unity.exe" -projectPath "D:\Documents\Projects\q3-client\project\q3_unity_project"\n';
        ini += '; 例子2:\n';
        ini += '; Code="D:\Programs\Microsoft VS Code\Code.exe" "D:\Documents\Projects\q3-client\project\q3_unity_project"\n';
        ini += '; 例子3:\n';
        ini += '; ClashVerge="D:\Program\Clash Verge\clash-verge.exe"\n\n';
        ini += '; 应用名称=完整可执行文件路径 参数1 参数2 ...\n';
        ini += '[app]\n';

        this.apps.forEach(app => {
            const quotedParams = app.params
                .map(p => this.quotePath(p.value))
                .filter(p => p !== '')
                .join(' ');
            if (quotedParams) {
                ini += `${app.name}=${quotedParams}\n`;
            }
        });

        ini += '\n[setting]\n';
        ini += `; 是否写入日志文件\nWriteLog2Log=${this.settings.WriteLog2Log}\n\n`;
        ini += `; CPU使用率阈值（%）：用于决定是否启动下一个应用\nCPUThreshold=${this.settings.CPUThreshold}\n\n`;
        ini += `; 最小启动间隔（秒）：确保应用启动有基本间隔\nMinInterval=${this.settings.MinInterval}\n\n`;
        ini += `; 日志文件路径：指定日志保存位置\nLogFilePath=${this.settings.LogFilePath}\n\n`;
        ini += `; 最大等待时间（秒）：超过此时间强制启动下一个应用\nMaxWaitTime=${this.settings.MaxWaitTime}\n\n`;
        ini += `; 启动超时时间（秒）：判断应用是否成功启动的超时\nStartTimeout=${this.settings.StartTimeout}\n\n`;
        ini += `; 已运行应用处理方式：Skip（跳过）或 Restart（强制重启）\n`;
        ini += `AppAlreadyRunningAction=${this.settings.AppAlreadyRunningAction}\n`;

        return ini;
    }

    // 更新预览（带防抖）
    updatePreview() {
        // 清除之前的超时
        if (this.updatePreviewTimeout) {
            clearTimeout(this.updatePreviewTimeout);
        }

        // 设置新的超时，延迟50毫秒执行，避免频繁触发
        this.updatePreviewTimeout = setTimeout(() => {
            this.updateSettings();
            const preview = document.getElementById('preview');
            const iniContent = this.generateINI();
            const highlightedContent = Prism.highlight(iniContent, Prism.languages.ini, 'ini');
            preview.innerHTML = highlightedContent;
        }, 50);
    }

    // 复制预览内容
    async copyPreview() {
        try {
            await navigator.clipboard.writeText(this.generateINI());
            this.showNotification('已复制到剪贴板!', 'success');
        } catch (e) {
            this.showNotification('复制失败!', 'error');
        }
    }

    // 保存到文件
    async saveToFile() {
        try {
            const content = this.generateINI();

            // 尝试使用 File System Access API 直接写入文件
            if ('showSaveFilePicker' in window) {
                try {
                    const handle = await window.showSaveFilePicker({
                        suggestedName: 'apps.ini',
                        types: [{
                            description: 'INI 文件',
                            accept: { 'text/plain': ['.ini'] }
                        }]
                    });

                    const writable = await handle.createWritable();
                    await writable.write(content);
                    await writable.close();

                    this.hasChanges = false;
                    this.saveToStorage();
                    this.showNotification('配置已保存到 apps.ini!', 'success');
                    return;
                } catch (e) {
                    if (e.name !== 'AbortError') {
                        console.log('无法使用 File System Access API，使用下载方式:', e);
                    } else {
                        return; // 用户取消保存
                    }
                }
            }

            // 降级方案：使用传统下载方式
            const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'apps.ini';
            a.click();
            URL.revokeObjectURL(url);
            this.hasChanges = false;
            this.saveToStorage();
            this.showNotification('配置已下载，请将其替换项目目录中的 apps.ini', 'info');
        } catch (e) {
            console.error('保存失败:', e);
            this.showNotification('保存失败: ' + e.message, 'error');
        }
    }

    // 导出配置
    exportConfig() {
        const content = JSON.stringify({ apps: this.apps, settings: this.settings }, null, 2);
        const blob = new Blob([content], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'config-export.json';
        a.click();
        URL.revokeObjectURL(url);
        this.showNotification('配置已导出!', 'success');
    }

    // 导入配置
    importConfig(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const content = e.target.result;

                // 尝试解析 JSON 导出文件
                if (file.name.endsWith('.json')) {
                    const data = JSON.parse(content);
                    this.apps = data.apps || [];
                    this.settings = data.settings || this.getDefaultSettings();
                } else {
                    // 解析 INI 文件
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
        event.target.value = ''; // 重置文件输入
    }

    // 加载 INI 文件（手动加载）
    loadIniFile(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const content = e.target.result;
                this.parseINI(content);
                this.hasChanges = false;
                this.saveToStorage(); // 保存到本地存储
                this.render();
                this.updatePreview();
                this.showNotification('已加载配置文件!', 'success');
            } catch (error) {
                console.error('加载失败:', error);
                this.showNotification('加载失败: ' + error.message, 'error');
            }
        };
        reader.readAsText(file);
        event.target.value = ''; // 重置文件输入
    }

    // 解析 INI 文件
    parseINI(content) {
        const lines = content.split('\n');
        let currentSection = null;
        this.apps = [];
        this.settings = this.getDefaultSettings();

        lines.forEach(line => {
            line = line.trim();

            // 跳过空行和注释
            if (!line || line.startsWith(';') || line.startsWith('#')) return;

            // 解析区块
            if (line.startsWith('[') && line.endsWith(']')) {
                currentSection = line.substring(1, line.length - 1);
                return;
            }

            // 解析键值对
            if (line.includes('=')) {
                const [key, value] = line.split('=').map(s => s.trim());

                if (currentSection === 'app') {
                    // 解析应用参数
                    const params = this.parseParams(value);
                    this.apps.push({
                        id: Date.now().toString() + '_' + this.apps.length,
                        name: key,
                        params
                    });
                } else if (currentSection === 'setting') {
                    this.settings[key] = value;
                }
            }
        });
    }

    // 解析参数字符串
    parseParams(value) {
        if (!value || value.trim() === '') return [];

        const params = [];
        let current = '';
        let inQuotes = false;
        let i = 0;

        while (i < value.length) {
            const char = value[i];

            if (char === '"') {
                // 跳过引号，切换引号状态
                inQuotes = !inQuotes;
                i++;
            } else if (char === ' ' && !inQuotes) {
                // 在引号外遇到空格，保存当前参数
                if (current.trim()) {
                    params.push({
                        id: Date.now().toString() + '_' + params.length,
                        value: current.trim()
                    });
                    current = '';
                }
                i++;
            } else {
                current += char;
                i++;
            }
        }

        // 保存最后一个参数
        if (current.trim()) {
            params.push({
                id: Date.now().toString() + '_' + params.length,
                value: current.trim()
            });
        }

        return params;
    }

    // 显示通知
    showNotification(message, type = 'info') {
        const notification = document.getElementById('notification');
        notification.textContent = message;
        notification.className = `notification notification-${type}`;
        notification.style.display = 'block';

        setTimeout(() => {
            notification.style.display = 'none';
        }, 3000);
    }

    // HTML 转义
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// 确保页面加载完成后初始化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.editor = new ConfigEditor();
    });
} else {
    window.editor = new ConfigEditor();
}
