class GDIplus {
    __New() {
        if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
            DllCall("LoadLibrary", "Str", "gdiplus")
        VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
        DllCall("gdiplus\GdiplusStartup", "UPtrP", pToken, "Ptr", &si, "Ptr", 0)
        this.token := pToken
    }
    __Delete() {
        DllCall("gdiplus\GdiplusShutdown", "Ptr", this.token)
        if hModule := DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
            DllCall("FreeLibrary", "Ptr", hModule)
    }
    CreateBitmapFromStream(pStream) {
        DllCall("gdiplus\GdipCreateBitmapFromStream", "Ptr", pStream, "PtrP", pBitmap)
        Return pBitmap
    }
    CreateHBITMAPFromBitmap(pBitmap, background := 0xffffffff) {
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", hbm, "UInt", background)
        return hbm
    }
    DisposeImage(pBitmap) {
        return DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    }
}