#ifndef NAVLIB_DEFINES_H_INCLUDED_
#define NAVLIB_DEFINES_H_INCLUDED_
// <copyright file="navlib.h" company="3Dconnexion">
// -------------------------------------------------------------------------------------------------
// Copyright (c) 2014-2021 3Dconnexion. All rights reserved.
//
// This file and source code are an integral part of the "3Dconnexion Software Developer Kit",
// including all accompanying documentation, and is protected by intellectual property laws. All use
// of the 3Dconnexion Software Developer Kit is subject to the License Agreement found in the
// "LicenseAgreementSDK.txt" file. All rights not expressly granted by 3Dconnexion are reserved.
// -------------------------------------------------------------------------------------------------
// </copyright>
// <history>
// *************************************************************************************************
// File History
//
// $Id: navlib_defines.h 19940 2023-01-25 07:17:44Z mbonk $
//
// 01/23/14 MSB Initial design
// </history>
// <description>
// *************************************************************************************************
// File Description
//
// This header file defines the macros used in the 3dconnexion interface and header files.
//
// *************************************************************************************************
// </description>

// Invalid handle
#define INVALID_NAVLIB_HANDLE 0

// Navlib facility used to generate error codes
// Note this is identical to FACILITY_ITF on windows
#define FACILITY_NAVLIB 4

// resources
#define NAVLIB_IDB_ManualPivot 0x6004
#define NAVLIB_IDB_AutoPivot 0x6005

#if defined(__cplusplus)
#define NAVLIB_BEGIN_ namespace navlib {
#define NAVLIB_END_ }
#define NAVLIB_ ::navlib::
#define USING_NAVLIB_ using namespace navlib;
#else
#define NAVLIB_BEGIN_
#define NAVLIB_END_
#define NAVLIB_
#define USING_NAVLIB_
#endif

#if defined(_MSC_VER) && defined(NAVLIB_EXPORTS)
#define NAVLIB_DLLAPI_ extern "C" __declspec(dllexport)
#elif defined(__cplusplus)
#define NAVLIB_DLLAPI_ extern "C"
#else
#define NAVLIB_DLLAPI_ extern "C"
#endif

#ifndef NOEXCEPT
#if defined(_MSC_VER) && (_MSC_VER <= 1800)
#ifdef _NOEXCEPT
#define NOEXCEPT _NOEXCEPT
#else
#define NOEXCEPT
#endif
#else
#define NOEXCEPT noexcept
#endif
#endif

#endif // NAVLIB_DEFINES_H_INCLUDED_
