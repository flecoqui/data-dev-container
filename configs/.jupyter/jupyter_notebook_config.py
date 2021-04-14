#c.Application.log_datefmt = '%Y-%m-%d %H:%M:%S'
#c.Application.log_format = '[%(name)s]%(highlevel)s %(message)s'
#c.Application.log_level = 30
#c.JupyterApp.answer_yes = False
#c.JupyterApp.config_file = ''
#c.JupyterApp.config_file_name = ''
#c.JupyterApp.generate_config = False
#c.NotebookApp.allow_credentials = False
#c.NotebookApp.allow_origin = ''
#c.NotebookApp.allow_origin_pat = ''
#c.NotebookApp.allow_password_change = True
#c.NotebookApp.allow_remote_access = False
c.NotebookApp.allow_root = True
#c.NotebookApp.base_project_url = '/'
#c.NotebookApp.base_url = '/'
#c.NotebookApp.browser = ''
#c.NotebookApp.certfile = ''
#c.NotebookApp.client_ca = ''
#c.NotebookApp.config_manager_class = 'notebook.services.config.manager.ConfigManager'
#c.NotebookApp.contents_manager_class = 'notebook.services.contents.largefilemanager.LargeFileManager'
#c.NotebookApp.cookie_options = {}
#c.NotebookApp.cookie_secret = b''
#c.NotebookApp.cookie_secret_file = ''
#c.NotebookApp.custom_display_url = ''
#c.NotebookApp.default_url = '/tree'
#c.NotebookApp.disable_check_xsrf = False
#c.NotebookApp.enable_mathjax = True
#c.NotebookApp.extra_nbextensions_path = []
#c.NotebookApp.extra_services = []
#c.NotebookApp.extra_static_paths = []
#c.NotebookApp.extra_template_paths = []
#c.NotebookApp.file_to_run = ''
#c.NotebookApp.get_secure_cookie_kwargs = {}
#c.NotebookApp.ignore_minified_js = False
#c.NotebookApp.iopub_data_rate_limit = 1000000
#c.NotebookApp.iopub_msg_rate_limit = 1000
c.NotebookApp.ip = '0.0.0.0'
#c.NotebookApp.jinja_environment_options = {}
#c.NotebookApp.jinja_template_vars = {}
#c.NotebookApp.kernel_manager_class = 'notebook.services.kernels.kernelmanager.MappingKernelManager'
#c.NotebookApp.kernel_spec_manager_class = 'jupyter_client.kernelspec.KernelSpecManager'
#c.NotebookApp.keyfile = ''
#c.NotebookApp.local_hostnames = ['localhost']
#c.NotebookApp.login_handler_class = 'notebook.auth.login.LoginHandler'
#c.NotebookApp.logout_handler_class = 'notebook.auth.logout.LogoutHandler'
#c.NotebookApp.mathjax_config = 'TeX-AMS-MML_HTMLorMML-full,Safe'
#c.NotebookApp.mathjax_url = ''
#c.NotebookApp.max_body_size = 536870912
#c.NotebookApp.max_buffer_size = 536870912
#c.NotebookApp.min_open_files_limit = 0
#c.NotebookApp.nbserver_extensions = {}
#c.NotebookApp.notebook_dir = ''
#c.NotebookApp.open_browser = True
c.NotebookApp.password = ''
#c.NotebookApp.password_required = False
c.NotebookApp.port = 8888
#c.NotebookApp.port_retries = 50
#c.NotebookApp.pylab = 'disabled'
#c.NotebookApp.quit_button = True
#c.NotebookApp.rate_limit_window = 3
#c.NotebookApp.reraise_server_extension_failures = False
#c.NotebookApp.server_extensions = []
#c.NotebookApp.session_manager_class = 'notebook.services.sessions.sessionmanager.SessionManager'
#c.NotebookApp.shutdown_no_activity_timeout = 0
#c.NotebookApp.ssl_options = {}
#c.NotebookApp.terminado_settings = {}
#c.NotebookApp.terminals_enabled = True
c.NotebookApp.token = ''
#c.NotebookApp.tornado_settings = {}
#c.NotebookApp.trust_xheaders = False
#c.NotebookApp.use_redirect_file = True
#c.NotebookApp.webapp_settings = {}
#c.NotebookApp.webbrowser_open_new = 2
#c.NotebookApp.websocket_compression_options = None
#c.NotebookApp.websocket_url = ''
#c.ConnectionFileMixin.connection_file = ''
#c.ConnectionFileMixin.control_port = 0
#c.ConnectionFileMixin.hb_port = 0
#c.ConnectionFileMixin.iopub_port = 0
#c.ConnectionFileMixin.ip = ''
#c.ConnectionFileMixin.shell_port = 0
#c.ConnectionFileMixin.stdin_port = 0
#c.ConnectionFileMixin.transport = 'tcp'
c.KernelManager.autorestart = False
#c.KernelManager.kernel_cmd = []
#c.KernelManager.shutdown_wait_time = 5.0
#c.Session.buffer_threshold = 1024
#c.Session.check_pid = True
#c.Session.copy_threshold = 65536
#c.Session.debug = False
#c.Session.digest_history_size = 65536
#c.Session.item_threshold = 64
#c.Session.key = b''
#c.Session.keyfile = ''
#c.Session.metadata = {}
#c.Session.packer = 'json'
#c.Session.session = ''
#c.Session.signature_scheme = 'hmac-sha256'
#c.Session.unpacker = 'json'
#c.Session.username = 'username'
#c.MultiKernelManager.default_kernel_name = 'python3'
#c.MultiKernelManager.kernel_manager_class = 'jupyter_client.ioloop.IOLoopKernelManager'
#c.MultiKernelManager.shared_context = True
#c.MappingKernelManager.allowed_message_types = []
#c.MappingKernelManager.buffer_offline_messages = True
#c.MappingKernelManager.cull_busy = False
#c.MappingKernelManager.cull_connected = False
#c.MappingKernelManager.cull_idle_timeout = 0
#c.MappingKernelManager.cull_interval = 300
#c.MappingKernelManager.kernel_info_timeout = 60
#c.MappingKernelManager.root_dir = ''
#c.KernelSpecManager.ensure_native_kernel = True
#c.KernelSpecManager.kernel_spec_class = 'jupyter_client.kernelspec.KernelSpec'
#c.KernelSpecManager.whitelist = set()
#c.ContentsManager.allow_hidden = False
#c.ContentsManager.checkpoints = None
#c.ContentsManager.checkpoints_class = 'notebook.services.contents.checkpoints.Checkpoints'
#c.ContentsManager.checkpoints_kwargs = {}
#c.ContentsManager.files_handler_class = 'notebook.files.handlers.FilesHandler'
#c.ContentsManager.files_handler_params = {}
#c.ContentsManager.hide_globs = ['__pycache__', '*.pyc', '*.pyo', '.DS_Store', '*.so', '*.dylib', '*~']
#c.ContentsManager.pre_save_hook = None
c.ContentsManager.root_dir = '/workspace'
#c.ContentsManager.untitled_directory = 'Untitled Folder'
#c.ContentsManager.untitled_file = 'untitled'
#c.ContentsManager.untitled_notebook = 'Untitled'
#c.FileManagerMixin.use_atomic_writing = True
#c.FileContentsManager.delete_to_trash = True
#c.FileContentsManager.post_save_hook = None
#c.FileContentsManager.root_dir = ''
#c.FileContentsManager.save_script = False
#c.NotebookNotary.algorithm = 'sha256'
#c.NotebookNotary.db_file = ''
#c.NotebookNotary.secret = b''
#c.NotebookNotary.secret_file = ''
#c.NotebookNotary.store_factory = traitlets.Undefined
#c.GatewayClient.auth_token = None
#c.GatewayClient.ca_certs = None
#c.GatewayClient.client_cert = None
#c.GatewayClient.client_key = None
#c.GatewayClient.connect_timeout = 60.0
#c.GatewayClient.env_whitelist = ''
#c.GatewayClient.headers = '{}'
#c.GatewayClient.http_pwd = None
#c.GatewayClient.http_user = None
#c.GatewayClient.kernels_endpoint = '/api/kernels'
#c.GatewayClient.kernelspecs_endpoint = '/api/kernelspecs'
#c.GatewayClient.kernelspecs_resource_endpoint = '/kernelspecs'
#c.GatewayClient.request_timeout = 60.0
#c.GatewayClient.url = None
#c.GatewayClient.validate_cert = True
#c.GatewayClient.ws_url = None
c.KernelManager.autorestart=False
c.MappingKernelManager.kernel_info_timeout=20