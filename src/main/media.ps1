param([byte]$Key, [int]$Times = 1)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class CapriMedia {
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public static void Send(byte vk, int times) {
        for (int i = 0; i < times; i++) {
            keybd_event(vk, 0, 0, UIntPtr.Zero);
            keybd_event(vk, 0, 2, UIntPtr.Zero);
        }
    }
}
"@ -IgnoreWarnings

[CapriMedia]::Send($Key, $Times)
