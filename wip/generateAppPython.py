import sys
import os
import requests
import platform  # Add platform module
from PyQt5.QtWidgets import QApplication, QMainWindow, QMenu, QAction, QVBoxLayout, QWidget, QProgressBar, QMenuBar, QMessageBox
from PyQt5.QtWebEngineWidgets import QWebEngineView
from PyQt5.QtCore import QUrl, QTimer, Qt
from PyQt5.QtGui import QIcon

class WebApp(QMainWindow):
    def __init__(self, url, app_name):
        super().__init__()
        self.url = url
        self.app_name = app_name
        self.zoom_level = 1.0
        self.strict_mode_enabled = True

        self.initUI()

    def initUI(self):
        self.setWindowTitle(self.app_name)
        self.setGeometry(0, 0, 1024, 768)  # Remove margin by setting geometry to (0, 0)

        self.web_view = QWebEngineView()
        self.web_view.setUrl(QUrl(self.url))
        self.web_view.loadFinished.connect(self.on_load_finished)

        self.progress_bar = QProgressBar()
        self.progress_bar.setAlignment(Qt.AlignCenter)
        self.progress_bar.setMaximumHeight(20)
        self.progress_bar.setStyleSheet("background-color: black;")  # Set background color

        layout = QVBoxLayout()
        layout.setContentsMargins(0, 0, 0, 0)  # Remove margins
        layout.addWidget(self.progress_bar)  # Place progress bar above the web view
        layout.addWidget(self.web_view)

        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        self.create_menus()

        self.show()

        QTimer.singleShot(7000, self.on_load_finished)

    def create_menus(self):
        menubar = self.menuBar()

        file_menu = menubar.addMenu('File')
        new_instance_action = QAction('New Instance', self)
        new_instance_action.triggered.connect(self.new_instance)
        file_menu.addAction(new_instance_action)

        # Add "Create Shortcut" action
        create_shortcut_action = QAction('Create Shortcut', self)
        create_shortcut_action.triggered.connect(self.create_shortcut)
        file_menu.addAction(create_shortcut_action)

        edit_menu = menubar.addMenu('Edit')
        cut_action = QAction('Cut', self)
        cut_action.setShortcut('Ctrl+X')
        cut_action.triggered.connect(self.cut)
        edit_menu.addAction(cut_action)

        copy_action = QAction('Copy', self)
        copy_action.setShortcut('Ctrl+C')
        copy_action.triggered.connect(self.copy)
        edit_menu.addAction(copy_action)

        paste_action = QAction('Paste', self)
        paste_action.setShortcut('Ctrl+V')
        paste_action.triggered.connect(self.paste)
        edit_menu.addAction(paste_action)

        select_all_action = QAction('Select All', self)
        select_all_action.setShortcut('Ctrl+A')
        select_all_action.triggered.connect(self.select_all)
        edit_menu.addAction(select_all_action)

        view_menu = menubar.addMenu('View')
        go_home_action = QAction('Go Home', self)
        go_home_action.setShortcut('Ctrl+Shift+H')
        go_home_action.triggered.connect(self.go_home)
        view_menu.addAction(go_home_action)

        go_backwards_action = QAction('Go Backwards', self)
        go_backwards_action.setShortcut('Ctrl+[')
        go_backwards_action.triggered.connect(self.go_backwards)
        view_menu.addAction(go_backwards_action)

        zoom_in_action = QAction('Zoom In', self)
        zoom_in_action.setShortcut('Ctrl++')
        zoom_in_action.triggered.connect(self.zoom_in)
        view_menu.addAction(zoom_in_action)

        zoom_out_action = QAction('Zoom Out', self)
        zoom_out_action.setShortcut('Ctrl+-')
        zoom_out_action.triggered.connect(self.zoom_out)
        view_menu.addAction(zoom_out_action)

        restore_zoom_action = QAction('Restore Zoom', self)
        restore_zoom_action.setShortcut('Ctrl+0')
        restore_zoom_action.triggered.connect(self.restore_zoom)
        view_menu.addAction(restore_zoom_action)

        minimize_action = QAction('Minimize', self)
        minimize_action.setShortcut('Ctrl+M')
        minimize_action.triggered.connect(self.minimize_window)
        view_menu.addAction(minimize_action)

        help_menu = menubar.addMenu('Help')
        send_feedback_action = QAction('Send Feedback', self)
        send_feedback_action.triggered.connect(self.send_feedback)
        help_menu.addAction(send_feedback_action)

        disable_strict_mode_action = QAction('Disable Strict Mode', self)
        disable_strict_mode_action.triggered.connect(self.disable_strict_mode)
        help_menu.addAction(disable_strict_mode_action)

    def on_load_finished(self):
        self.progress_bar.setValue(100)
        self.progress_bar.hide()

    def new_instance(self):
        os.system(f'python3 {sys.argv[0]} {self.url} {self.app_name}')

    def cut(self):
        self.web_view.triggerPageAction(QWebEngineView.Cut)

    def copy(self):
        self.web_view.triggerPageAction(QWebEngineView.Copy)

    def paste(self):
        self.web_view.triggerPageAction(QWebEngineView.Paste)

    def select_all(self):
        self.web_view.triggerPageAction(QWebEngineView.SelectAll)

    def go_home(self):
        self.web_view.setUrl(QUrl(self.url))

    def go_backwards(self):
        self.web_view.back()

    def zoom_in(self):
        self.zoom_level += 0.1
        self.web_view.setZoomFactor(self.zoom_level)

    def zoom_out(self):
        self.zoom_level -= 0.1
        self.web_view.setZoomFactor(self.zoom_level)

    def restore_zoom(self):
        self.zoom_level = 1.0
        self.web_view.setZoomFactor(self.zoom_level)

    def minimize_window(self):
        self.showMinimized()

    def send_feedback(self):
        QUrl("https://github.com/iairu/shortcut/issues/new")

    def disable_strict_mode(self):
        self.strict_mode_enabled = False
        QMessageBox.information(self, "Strict Mode Disabled", "Strict mode has been disabled. No addresses will be blocked.")

    def create_shortcut(self):
        if platform.system() == 'Darwin':  # macOS
            self.create_macos_shortcut()
        else:
            QMessageBox.warning(self, "Unsupported OS", "Shortcut creation is not supported on this operating system.")

    def create_macos_shortcut(self):
        script = f'''
        osascript -e 'tell application "Finder" to make alias file to POSIX file "/bin/bash" at POSIX file "/Applications"'
        osascript -e 'tell application "Finder" to set the contents of alias file "/Applications/bash" to "source {os.path.dirname(os.path.abspath(sys.argv[0]))}/venv/bin/activate && python3 {os.path.abspath(sys.argv[0])} {self.url} {self.app_name}"'
        '''
        os.system(script)
        QMessageBox.information(self, "Shortcut Created", "Shortcut has been created in the Applications folder.")

def main():
    if len(sys.argv) != 3:
        print("Usage: python generateAppPython.py <URL> <App Name>")
        sys.exit(1)

    url = sys.argv[1]
    app_name = sys.argv[2]

    app = QApplication(sys.argv)
    web_app = WebApp(url, app_name)
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()