using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Threading;

namespace Screenshot
{
    class Program
    {
        static void Main(string[] args)
        {
            ScreenCapture cap = new ScreenCapture();
            IntPtr hwd = (IntPtr)5048990;
            StringBuilder title = new StringBuilder(256);
            User32.GetWindowText(hwd, title, title.Capacity);
            StringBuilder clsName = new StringBuilder(256);
            User32.GetClassName(hwd, clsName, clsName.Capacity);
            IntPtr hwdnew = User32.FindWindow(clsName.ToString(), title.ToString());
            Console.WriteLine(title.ToString() + "; " + clsName.ToString());
            cap.ShowAppWindow(hwd);
            cap.CaptureWindowFromTop(hwd, @"C:\Users\Johney_Local\Desktop\Screenshot\test.jpg", ImageFormat.Jpeg);
            //cap.CaptureAppWindowToFile(hwd, @"C:\Users\Johney_Local\Desktop\Screenshot\test.jpg", ImageFormat.Jpeg);
        }
    }

    /// <summary> 
    /// Helper class containing User32 API functions 
    /// </summary> 
    static class User32
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT
        {
            public int left;
            public int top;
            public int right;
            public int bottom;
        }

        public enum CMDSHOW
        {
            Close = 0,
            Normal = 1,
            Minimize = 2,
            Maximize = 3
        }

        public enum UINT
        {
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

        [DllImport("user32.dll")]
        public static extern IntPtr GetDesktopWindow();
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowDC(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern IntPtr ReleaseDC(IntPtr hWnd, IntPtr hDC);
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowRect(IntPtr hWnd, out Rectangle rect);
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")]
        public static extern IntPtr SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        [DllImport("user32.dll")]
        public static extern IntPtr GetClassName(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        [DllImport("user32.dll")]
        public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdcBlt, UInt32 nFlags);
        [DllImport("user32.dll")]
        public static extern IntPtr ShowWindow(IntPtr hwnd, CMDSHOW showState);
        [DllImport("user32.dll")]
        public static extern IntPtr SetActiveWindow(IntPtr hwnd);
        [DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, int hWndInsertAfter,int X,int Y,int cx,int cy,UINT uFlags);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        [DllImport("user32.dll", EntryPoint = "FindWindow", SetLastError = true)]
        public static extern IntPtr FindWindowByCaption(int ZeroOnly, string lpWindowName);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr ProcessId);
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint GetCurrentThreadId();
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    }

    /// <summary> 
    /// Helper class containing Gdi32 API functions 
    /// </summary> 
    static class GDI32
    {

        public const int SRCCOPY = 0x00CC0020; // BitBlt dwRop parameter 
        [DllImport("gdi32.dll")]
        public static extern bool BitBlt(IntPtr hObject, int nXDest, int nYDest,
          int nWidth, int nHeight, IntPtr hObjectSource,
          int nXSrc, int nYSrc, int dwRop);
        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth,
          int nHeight);
        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
        [DllImport("gdi32.dll")]
        public static extern bool DeleteDC(IntPtr hDC);
        [DllImport("gdi32.dll")]
        public static extern bool DeleteObject(IntPtr hObject);
        [DllImport("gdi32.dll")]
        public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
    }

    public class ScreenCapture
    {
        public void ActiveAndCaptureWindow(IntPtr handle, string path)
        {
            StringBuilder title = new StringBuilder(256);
            User32.GetWindowText(handle, title, title.Capacity);
            Console.WriteLine(title);
            User32.SetForegroundWindow(handle);
            Rectangle windowRect = new Rectangle();
            User32.GetWindowRect(handle, out windowRect);
            int width = windowRect.Right - windowRect.Left;
            int height = windowRect.Bottom - windowRect.Top;

            Rectangle bounds = Rectangle.FromLTRB(windowRect.Left, windowRect.Top, width, height);
            Bitmap bmp = new Bitmap(width, height);
            Graphics graphics = Graphics.FromImage(bmp);
            graphics.CopyFromScreen(bounds.Location, Point.Empty, bounds.Size);
            bmp.Save(path);

            graphics.Dispose();
            bmp.Dispose();
        }

        /// <summary> 
        /// Creates an Image object containing a screen shot the active window 
        /// </summary> 
        /// <returns></returns> 
        public Image CaptureAppWindow(IntPtr handle)
        {
            return CaptureWindow(handle);
        }
        /// <summary> 
        /// Creates an Image object containing a screen shot of the entire desktop 
        /// </summary> 
        /// <returns></returns> 
        public Image CaptureScreen()
        {
            return CaptureWindow(User32.GetDesktopWindow());
        }

        public void ShowAppWindow(IntPtr handle)
        {
            const int HWND_BOTTOM = 1;
            const int HWND_NOTOPMOST = -2;
            const int HWND_TOP = 0;
            const int HWND_TOPMOST = -1;

            IntPtr hForeWnd = User32.GetForegroundWindow();
            uint dwForeID = User32.GetWindowThreadProcessId(hForeWnd, IntPtr.Zero);
            uint dwCurID = User32.GetCurrentThreadId();
            User32.AttachThreadInput(dwCurID, dwForeID, true);
            User32.ShowWindow(handle, User32.CMDSHOW.Normal);
            Thread.Sleep(250);
            User32.SetWindowPos(handle, HWND_TOPMOST, 0, 0, 0, 0, User32.UINT.SWP_NOSIZE | User32.UINT.SWP_NOMOVE);
            User32.SetWindowPos(handle, HWND_NOTOPMOST, 0, 0, 0, 0, User32.UINT.SWP_NOSIZE | User32.UINT.SWP_NOMOVE);
            User32.SetForegroundWindow(handle);
            Thread.Sleep(250);
            User32.AttachThreadInput(dwCurID, dwForeID, false);
        }

        public void CaptureWindowFromTop(IntPtr handle, string saveLocation, ImageFormat format)
        {
            Rectangle rect = new Rectangle();
            User32.GetWindowRect(handle, out rect);
            Image img = new Bitmap(rect.Width - rect.X, rect.Height - rect.Y);
            Graphics graph = Graphics.FromImage(img);
            graph.CopyFromScreen(rect.X, rect.Y, 0, 0, Screen.FromHandle(handle).Bounds.Size);
            img.Save(saveLocation, format);

            graph.Dispose();
            img.Dispose();
        }

        /// <summary> 
        /// Creates an Image object containing a screen shot of a specific window 
        /// </summary> 
        /// <param name="handle">The handle to the window. (In windows forms, this is obtained by the Handle property)</param> 
        /// <returns></returns> 
        private Image CaptureWindow(IntPtr handle)
        {
            // get te hDC of the target window 
            IntPtr hdcSrc = User32.GetWindowDC(handle);
            // get the size 
            Rectangle rect = new Rectangle();
            User32.GetWindowRect(handle, out rect);
            int width = rect.Width - rect.X;
            int height = rect.Height - rect.Y;

            // create a bitmap we can copy it to, 
            // using GetDeviceCaps to get the width/height 
            IntPtr hBitmap = GDI32.CreateCompatibleBitmap(hdcSrc, width, height);
            // create a device context we can copy to 
            IntPtr hdcDest = GDI32.CreateCompatibleDC(hdcSrc);
            // select the bitmap object 
            IntPtr hOld = GDI32.SelectObject(hdcDest, hBitmap);

            // bitblt over 
            GDI32.BitBlt(hdcDest, 0, 0, width, height, hdcSrc, 0, 0, GDI32.SRCCOPY);
            //Print window
            User32.PrintWindow(handle, hdcDest, 0);

            // restore selection 
            GDI32.SelectObject(hdcDest, hOld);

            // get a .NET image object for it 
            Image img = Image.FromHbitmap(hBitmap);
            // free up the Bitmap object 
            GDI32.DeleteObject(hBitmap);
            // clean up 
            GDI32.DeleteDC(hdcDest);
            User32.ReleaseDC(handle, hdcSrc);

            return img;
        }

        /// <summary> 
        /// Captures a screen shot of the active window, and saves it to a file 
        /// </summary> 
        /// <param name="filename"></param> 
        /// <param name="format"></param> 
        public void CaptureAppWindowToFile(IntPtr hwd, string filename, ImageFormat format)
        {
            Image img = CaptureAppWindow(hwd);
            img.Save(filename, format);
        }
        /// <summary> 
        /// Captures a screen shot of the entire desktop, and saves it to a file 
        /// </summary> 
        /// <param name="filename"></param> 
        /// <param name="format"></param> 
        public void CaptureScreenToFile(string filename, ImageFormat format)
        {
            Image img = CaptureScreen();
            img.Save(filename, format);
        }
    }
}
