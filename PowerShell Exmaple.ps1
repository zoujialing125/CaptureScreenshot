
Function Take-ScreenShot { 
    <#   
.SYNOPSIS   
    Used to take a screenshot of the desktop or the active window.  
.DESCRIPTION   
    Used to take a screenshot of the desktop or the active window and save to an image file if needed. 
.PARAMETER screen 
    Screenshot of the entire screen 
.PARAMETER activeWindow 
    Screenshot of the active window 
.PARAMETER appWindow 
    Screenshot of the specific app window 
.PARAMETER appHandle
    Screenshot of the specific app window handle
.PARAMETER appProcessName 
    Screenshot of the specific app process name 
.PARAMETER appWindowText 
    Screenshot of the specific app window text
.PARAMETER file 
    Name of the file to save as. Default is image.bmp 
.PARAMETER imagetype 
    Type of image being saved. Can use JPEG,BMP,PNG. Default is bitmap(bmp)   
.PARAMETER print 
    Sends the screenshot directly to your default printer       
.INPUTS 
.OUTPUTS     
.NOTES   
    Name: Take-ScreenShot 
    Author: Boe Prox 
    DateCreated: 07/25/2010      
.EXAMPLE   
    Take-ScreenShot -activewindow 
    Takes a screen shot of the active window         
.EXAMPLE   
    Take-ScreenShot -Screen 
    Takes a screenshot of the entire desktop 
.EXAMPLE   
    Take-ScreenShot -activewindow -file "C:\image.bmp" -imagetype bmp 
    Takes a screenshot of the active window and saves the file named image.bmp with the image being bitmap 
.EXAMPLE   
    Take-ScreenShot -screen -file "C:\image.png" -imagetype png     
    Takes a screenshot of the entire desktop and saves the file named image.png with the image being png 
.EXAMPLE   
    Take-ScreenShot -Screen -print 
    Takes a screenshot of the entire desktop and sends to a printer 
.EXAMPLE   
    Take-ScreenShot -ActiveWindow -print 
    Takes a screenshot of the active window and sends to a printer     
#>   
#Requires -Version 2 
        [cmdletbinding( 
                SupportsShouldProcess = $True, 
                DefaultParameterSetName = "screen", 
                ConfirmImpact = "low" 
        )] 
Param ( 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "screen", 
            ValueFromPipeline = $True)] 
            [switch]$screen, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "window", 
            ValueFromPipeline = $False)] 
            [switch]$activeWindow, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "appWindow", 
            ValueFromPipeline = $False)] 
            [switch]$appWindow, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [System.IntPtr]$appHandle, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string]$appProcessName,      
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string]$appWindowText, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string]$file,  
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string] 
            [ValidateSet("bmp","jpeg","png")] 
            $imagetype = "bmp", 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [switch]$print                        
        
) 
# C# code 
$code = @' 
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ScreenShotDemo {
  /// <summary> 
  /// Provides functions to capture the entire screen, or a particular window, and save it to a file. 
  /// </summary> 
  public class ScreenCapture {
    /// <summary> 
    /// Creates an Image object containing a screen shot the active window 
    /// </summary> 
    /// <returns></returns> 
    public Image CaptureActiveWindow () {
      return CaptureWindow (User32.GetForegroundWindow ());
    }
    /// <summary> 
    /// Creates an Image object containing a screen shot of the entire desktop 
    /// </summary> 
    /// <returns></returns> 
    public Image CaptureScreen () {
      return CaptureWindow (User32.GetDesktopWindow ());
    }

    /// <summary> 
    /// Creates an Image object containing a screen shot of the appointed app window 
    /// </summary> 
    /// <returns></returns> 
    public Image CaptureAppWindow (string appWinTitle) {
      return CaptureAppScreen (GetAppHandleByTitle(appWinTitle));
    }

    public Image CaptureAppWindow (IntPtr handle) {
      return CaptureAppScreen (handle);
    }

    /// <summary> 
    /// Creates an Image object containing a screen shot of a specific window 
    /// </summary> 
    /// <param name="handle">The handle to the window. (In windows forms, this is obtained by the Handle property)</param> 
    /// <returns></returns> 
    private Image CaptureWindow (IntPtr handle) {

      // get te hDC of the target window 
      IntPtr hdcSrc = User32.GetWindowDC (handle);
      // get the size 
      Rectangle rect = new Rectangle ();
      User32.GetWindowRect (handle, out rect);
      int width = rect.Width - rect.X;
      int height = rect.Height - rect.Y;

      // create a bitmap we can copy it to, 
      // using GetDeviceCaps to get the width/height 
      IntPtr hBitmap = GDI32.CreateCompatibleBitmap (hdcSrc, width, height);
      // create a device context we can copy to 
      IntPtr hdcDest = GDI32.CreateCompatibleDC (hdcSrc);
      // select the bitmap object 
      IntPtr hOld = GDI32.SelectObject (hdcDest, hBitmap);

      // bitblt over 
      GDI32.BitBlt (hdcDest, 0, 0, width, height, hdcSrc, 0, 0, GDI32.SRCCOPY);
      //Print window
      User32.PrintWindow (handle, hdcDest, 0);

      // restore selection 
      GDI32.SelectObject (hdcDest, hOld);

      // get a .NET image object for it 
      Image img = Image.FromHbitmap (hBitmap);
      // free up the Bitmap object 
      GDI32.DeleteObject (hBitmap);
      // clean up 
      GDI32.DeleteDC (hdcDest);
      User32.ReleaseDC (handle, hdcSrc);

      return img;
    }
    
    private IntPtr GetAppHandleByTitle (string appWinTitle) {
      // Get the app title according to title name and class name
      IntPtr handle = User32.FindWindow (null, appWinTitle);

      return handle;
    }

    private Image CaptureAppScreen (IntPtr handle) {
      //const int HWND_BOTTOM = 1;
      const int HWND_NOTOPMOST = -2;
      //const int HWND_TOP = 0;
      const int HWND_TOPMOST = -1;

      // Put the app window on top of the screen
      IntPtr hForeWnd = User32.GetForegroundWindow ();
      uint dwForeID = User32.GetWindowThreadProcessId (hForeWnd, IntPtr.Zero);
      uint dwCurID = User32.GetCurrentThreadId ();
      User32.AttachThreadInput (dwCurID, dwForeID, true);
      User32.ShowWindow (handle, User32.CMDSHOW.Normal);
      Thread.Sleep (250);
      User32.SetWindowPos (handle, HWND_TOPMOST, 0, 0, 0, 0, User32.UINT.SWP_NOSIZE | User32.UINT.SWP_NOMOVE);
      User32.SetWindowPos (handle, HWND_NOTOPMOST, 0, 0, 0, 0, User32.UINT.SWP_NOSIZE | User32.UINT.SWP_NOMOVE);
      User32.SetForegroundWindow (handle);
      Thread.Sleep (250);
      User32.AttachThreadInput (dwCurID, dwForeID, false);

      // Create a instance to store img
      Rectangle rect = new Rectangle ();
      User32.GetWindowRect (handle, out rect);
      Image img = new Bitmap (rect.Width - rect.X, rect.Height - rect.Y);
      Graphics graph = Graphics.FromImage (img);
      graph.CopyFromScreen (rect.X, rect.Y, 0, 0, Screen.FromHandle (handle).Bounds.Size);

      return img;
    }

    /// <summary> 
    /// Captures a screen shot of the active window, and saves it to a file 
    /// </summary> 
    /// <param name="filename"></param> 
    /// <param name="format"></param> 
    public void CaptureActiveWindowToFile (string filename, ImageFormat format) {
      Image img = CaptureActiveWindow ();
      img.Save (filename, format);
    }

    /// <summary> 
    /// Captures a screen shot of the entire desktop, and saves it to a file 
    /// </summary> 
    /// <param name="filename"></param> 
    /// <param name="format"></param> 
    public void CaptureScreenToFile (string filename, ImageFormat format) {
      Image img = CaptureScreen ();
      img.Save (filename, format);
    }

    public void CaptureAppWindowToFile (string filename, ImageFormat format, string appWinTitle) 
    {
      Image img = CaptureAppWindow (GetAppHandleByTitle(appWinTitle));
      img.Save (filename, format);
    }

    public void CaptureAppWindowToFile (string filename, ImageFormat format, IntPtr handle) 
    {
      Image img = CaptureAppWindow (handle);
      img.Save (filename, format);
    }

    /// <summary> 
    /// Helper class containing User32 API functions 
    /// </summary> 
    static class User32 {
      [StructLayout (LayoutKind.Sequential)]
      public struct RECT {
        public int left;
        public int top;
        public int right;
        public int bottom;
      }

      public enum CMDSHOW {
        Close = 0,
        Normal = 1,
        Minimize = 2,
        Maximize = 3
      }

      public enum UINT {
        SWP_ASYNCWINDOWPOS = 0x4000,
        SWP_DEFERERASE = 0x2000,
        SWP_DRAWFRAME = 0x0020,
        SWP_FRAMECHANGED = 0x0020,
        SWP_HIDEWINDOW = 0x0080,
        SWP_NOACTIVATE = 0x0010,
        SWP_NOCOPYBITS = 0x0100,
        SWP_NOMOVE = 0x0002,
        SWP_NOOWNERZORDER = 0x0200,
        SWP_NOREDRAW = 0x0008,
        SWP_NOREPOSITION = 0x0200,
        SWP_NOSENDCHANGING = 0x0400,
        SWP_NOSIZE = 0x0001,
        SWP_NOZORDER = 0x0004,
        SWP_SHOWWINDOW = 0x0040
      }

      [DllImport ("user32.dll")]
      public static extern IntPtr GetDesktopWindow ();
      [DllImport ("user32.dll")]
      public static extern IntPtr GetWindowDC (IntPtr hWnd);
      [DllImport ("user32.dll")]
      public static extern IntPtr ReleaseDC (IntPtr hWnd, IntPtr hDC);
      [DllImport ("user32.dll")]
      public static extern IntPtr GetWindowRect (IntPtr hWnd, out Rectangle rect);
      [DllImport ("user32.dll")]
      public static extern IntPtr GetForegroundWindow ();
      [DllImport ("user32.dll")]
      public static extern IntPtr SetForegroundWindow (IntPtr hWnd);
      [DllImport ("user32.dll")]
      public static extern IntPtr GetWindowText (IntPtr hWnd, StringBuilder lpString, int nMaxCount);
      [DllImport ("user32.dll")]
      public static extern IntPtr GetClassName (IntPtr hWnd, StringBuilder lpString, int nMaxCount);
      [DllImport ("user32.dll")]
      public static extern bool PrintWindow (IntPtr hwnd, IntPtr hdcBlt, UInt32 nFlags);
      [DllImport ("user32.dll")]
      public static extern IntPtr ShowWindow (IntPtr hwnd, CMDSHOW showState);
      [DllImport ("user32.dll")]
      public static extern IntPtr SetActiveWindow (IntPtr hwnd);
      [DllImport ("user32.dll")]
      public static extern bool SetWindowPos (IntPtr hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
      [DllImport ("user32.dll", SetLastError = true)]
      public static extern IntPtr FindWindow (string lpClassName, string lpWindowName);
      [DllImport ("user32.dll", EntryPoint = "FindWindow", SetLastError = true)]
      public static extern IntPtr FindWindowByCaption (int ZeroOnly, string lpWindowName);
      [DllImport ("user32.dll", SetLastError = true)]
      public static extern uint GetWindowThreadProcessId (IntPtr hWnd, IntPtr ProcessId);
      [DllImport ("kernel32.dll", SetLastError = true)]
      public static extern uint GetCurrentThreadId ();
      [DllImport ("user32.dll", SetLastError = true)]
      public static extern bool AttachThreadInput (uint idAttach, uint idAttachTo, bool fAttach);
    }

    /// <summary> 
    /// Helper class containing Gdi32 API functions 
    /// </summary> 
    static class GDI32 {

      public const int SRCCOPY = 0x00CC0020; // BitBlt dwRop parameter 
      [DllImport ("gdi32.dll")]
      public static extern bool BitBlt (IntPtr hObject, int nXDest, int nYDest,
        int nWidth, int nHeight, IntPtr hObjectSource,
        int nXSrc, int nYSrc, int dwRop);
      [DllImport ("gdi32.dll")]
      public static extern IntPtr CreateCompatibleBitmap (IntPtr hDC, int nWidth,
        int nHeight);
      [DllImport ("gdi32.dll")]
      public static extern IntPtr CreateCompatibleDC (IntPtr hDC);
      [DllImport ("gdi32.dll")]
      public static extern bool DeleteDC (IntPtr hDC);
      [DllImport ("gdi32.dll")]
      public static extern bool DeleteObject (IntPtr hObject);
      [DllImport ("gdi32.dll")]
      public static extern IntPtr SelectObject (IntPtr hDC, IntPtr hObject);
    }
  }
}
'@ 
#User Add-Type to import the code 
add-type $code -ReferencedAssemblies 'System.Windows.Forms','System.Drawing' 
#Create the object for the Function 
$capture = New-Object ScreenShotDemo.ScreenCapture 

#Take screenshot of the entire screen 
If ($Screen) { 
    Write-Verbose "Taking screenshot of entire desktop" 
    #Save to a file 
    If ($file) { 
        If ($file -eq "") { 
            $file = "$pwd\Desktop\image.bmp" 
            } 
        Write-Verbose "Creating screen file: $file with imagetype of $imagetype" 
        $capture.CaptureScreenToFile($file,$imagetype) 
        } 
    ElseIf ($print) { 
        $img = $Capture.CaptureScreen() 
        $pd = New-Object System.Drawing.Printing.PrintDocument 
        $pd.Add_PrintPage({$_.Graphics.DrawImage(([System.Drawing.Image]$img), 0, 0)}) 
        $pd.Print() 
        }         
    Else { 
        $capture.CaptureScreen() 
        } 
    } 
#Take screenshot of the active window     
If ($ActiveWindow) { 
    Write-Verbose "Taking screenshot of the active window" 
    #Save to a file 
    If ($file) { 
        If ($file -eq "") { 
            $file = "$pwd\Desktop\image.bmp" 
            } 
        Write-Verbose "Creating activewindow file: $file with imagetype of $imagetype" 
        $capture.CaptureActiveWindowToFile($file,$imagetype) 
        } 
    ElseIf ($print) { 
        $img = $Capture.CaptureActiveWindow() 
        $pd = New-Object System.Drawing.Printing.PrintDocument 
        $pd.Add_PrintPage({$_.Graphics.DrawImage(([System.Drawing.Image]$img), 0, 0)}) 
        $pd.Print() 
        }         
    Else { 
        $capture.CaptureActiveWindow() 
        }     
    }      

#Take screenshot of the specific app window     
If ($appWindow) { 
    Write-Verbose "Taking screenshot of specific app window" 
    #Save to a file 
    If($appWindowText ){

        if($appHandle -eq $null){
            #Find app handle with process name and window key title text
            $procs = Get-Process | Where-Object {$_.ProcessName -eq $appProcessName}
            foreach($proc in $procs){
                $proHandle = $proc.MainWindowHandle
                if ($proHandle -and $proc.MainWindowTitle -like "*"+$appWindowText+"*"){
                    $appHandle = $proHandle
                    break
                }
            }
        }

        If ($file) { 
            If ($file -eq "") { 
                $file = "$pwd\Desktop\image.bmp" 
                } 
            Write-Verbose "Creating app window file: $file with imagetype of $imagetype" 
            $capture.CaptureAppWindowToFile($file,$imagetype,$appHandle) 
            } 
        ElseIf ($print) { 
            $img = $Capture.CaptureAppWindow($appHandle) 
            $pd = New-Object System.Drawing.Printing.PrintDocument 
            $pd.Add_PrintPage({$_.Graphics.DrawImage(([System.Drawing.Image]$img), 0, 0)}) 
            $pd.Print() 
            }         
        Else { 
            $capture.CaptureAppWindow($appHandle) 
            }     
        }
    Else {
        Write-Verbose "Please ensure input the parameters including app class name and app window text." 
        }
    }
    
}
