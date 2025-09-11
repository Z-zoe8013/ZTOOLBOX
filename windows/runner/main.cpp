#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Get primary monitor work area size
  RECT desktop_rect;
  SystemParametersInfo(SPI_GETWORKAREA, 0, &desktop_rect, 0);
  int screen_width = desktop_rect.right - desktop_rect.left;
  int screen_height = desktop_rect.bottom - desktop_rect.top;
  
  // Set window size
  Win32Window::Size size(380, 700);

  // Calculate position: right-aligned horizontally, centered vertically
  unsigned int x = screen_width - size.width - 20;
  unsigned int y = (screen_height - size.height) / 2;
  
  Win32Window::Point origin(x, y);
  
  if (!window.Create(L"ztoolbox", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}