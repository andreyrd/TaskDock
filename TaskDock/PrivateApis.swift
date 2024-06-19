//
//  PrivateApis.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/19/23.
//
//

import Cocoa


let CoreServiceBundle = CFBundleGetBundleWithIdentifier("com.apple.CoreServices" as CFString)

typealias LSASN = CFTypeRef
let kLSDefaultSessionID: Int32 = -2
let badgeLabelKey = "StatusLabel" // TODO: Is there a `_kLS*` constant for this?

typealias _LSCopyRunningApplicationArray_Type = @convention(c) (Int32) -> [LSASN]

let _LSCopyRunningApplicationArray: _LSCopyRunningApplicationArray_Type = {
    let untypedFnPtr = CFBundleGetFunctionPointerForName(CoreServiceBundle, "_LSCopyRunningApplicationArray" as CFString)
    return unsafeBitCast(untypedFnPtr, to: _LSCopyRunningApplicationArray_Type.self)
}()

typealias _LSCopyApplicationInformation_Type = @convention(c) (Int32, CFTypeRef, CFString?) -> [CFString: CFDictionary]

let _LSCopyApplicationInformation: _LSCopyApplicationInformation_Type = {
    let untypedFnPtr = CFBundleGetFunctionPointerForName(CoreServiceBundle, "_LSCopyApplicationInformation" as CFString)
    return unsafeBitCast(untypedFnPtr, to: _LSCopyApplicationInformation_Type.self)
}()

func getAllAppASNs() -> [LSASN] {
    _LSCopyRunningApplicationArray(kLSDefaultSessionID)
}

func getAppInfo(asn: LSASN, property: String? = nil) -> [String: Any] {
    _LSCopyApplicationInformation(kLSDefaultSessionID, asn, property as CFString?) as [String: Any]
}
