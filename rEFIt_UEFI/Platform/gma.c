/*
	Original patch by Nawcom
	http://forum.voodooprojects.org/index.php/topic,1029.0.html
*/

#include "Platform.h"
#include "gma.h"

#ifndef DEBUG_GMA
#ifndef DEBUG_ALL
#define DEBUG_GMA 1
#else
#define DEBUG_GMA DEBUG_ALL
#endif
#endif

#if DEBUG_GMA == 0
#define DBG(...)
#else
#define DBG(...) DebugLog(DEBUG_GMA, __VA_ARGS__)
#endif

extern CHAR8*						gDeviceProperties;

//Slice - corrected all values, still not sure
UINT8 GMAX3100_vals[28][4] = {
	{ 0x01, 0x00, 0x00, 0x00 },	//0 "AAPL,HasPanel"
	{ 0x01, 0x00, 0x00, 0x00 },	//1 "AAPL,SelfRefreshSupported"
	{ 0x01, 0x00, 0x00, 0x00 },	//2 "AAPL,aux-power-connected"
	{ 0x01, 0x00, 0x00, 0x08 },	//3 "AAPL,backlight-control"
	{ 0x00, 0x00, 0x00, 0x00 },	//4 "AAPL00,blackscreen-preferences"
	{ 0x56, 0x00, 0x00, 0x08 },	//5 "AAPL01,BacklightIntensity"
	{ 0x00, 0x00, 0x00, 0x00 },	//6 "AAPL01,blackscreen-preferences"
	{ 0x01, 0x00, 0x00, 0x00 },	//7 "AAPL01,DataJustify"
	{ 0x20, 0x00, 0x00, 0x00 },	//8 "AAPL01,Depth"
	{ 0x01, 0x00, 0x00, 0x00 },	//9 "AAPL01,Dither"
	{ 0x20, 0x03, 0x00, 0x00 },	//10 "AAPL01,Height"
	{ 0x00, 0x00, 0x00, 0x00 },	//11 "AAPL01,Interlace"
	{ 0x00, 0x00, 0x00, 0x00 },	//12 "AAPL01,Inverter"
	{ 0x08, 0x52, 0x00, 0x00 },	//13 "AAPL01,InverterCurrent"
	{ 0x00, 0x00, 0x00, 0x00 },	//14 "AAPL01,LinkFormat"
	{ 0x00, 0x00, 0x00, 0x00 },	//15 "AAPL01,LinkType"
	{ 0x01, 0x00, 0x00, 0x00 },	//16 "AAPL01,Pipe"
	{ 0x01, 0x00, 0x00, 0x00 },	//17 "AAPL01,PixelFormat"
	{ 0x01, 0x00, 0x00, 0x00 },	//18 "AAPL01,Refresh"
	{ 0x3B, 0x00, 0x00, 0x00 },	//19 "AAPL01,Stretch"
	{ 0xc8, 0x95, 0x00, 0x00 },	//20 "AAPL01,InverterFrequency"
	{ 0x6B, 0x10, 0x00, 0x00 },	//21 "subsystem-vendor-id"
	{ 0xA2, 0x00, 0x00, 0x00 },	//22 "subsystem-id"
  { 0x05, 0x00, 0x62, 0x01 },    //23 "AAPL,ig-platform-id" HD4000 //STLVNUB
  { 0x06, 0x00, 0x62, 0x01 },    //24 "AAPL,ig-platform-id" HD4000 iMac
  { 0x09, 0x00, 0x66, 0x01 },    //25 "AAPL,ig-platform-id" HD4000
  { 0x03, 0x00, 0x22, 0x0d },    //26 "AAPL,ig-platform-id" HD4600 //bcc9 http://www.insanelymac.com/forum/topic/290783-intel-hd-graphics-4600-haswell-working-displayport/
  { 0x00, 0x00, 0x62, 0x01 }   //27 - automatic solution
};
// 5 - 32Mb 6 - 48Mb 9 - 64Mb, 0 - 96Mb

UINT8 FakeID_126[] = {0x26, 0x01, 0x00, 0x00 };

UINT8 reg_TRUE[]	= { 0x01, 0x00, 0x00, 0x00 };
UINT8 reg_FALSE[] = { 0x00, 0x00, 0x00, 0x00 };

static struct gma_gpu_t KnownGPUS[] = {
	{ 0x0000, "Unknown"			},
	{ 0x2582, "GMA 915"	},
	{ 0x2592, "GMA 915"	},
	{ 0x27A2, "GMA 950"	},
	{ 0x27AE, "GMA 950"	},
//	{ 0x27A6, "Mobile GMA950"	}, //not a GPU
	{ 0xA011, "Mobile GMA3150"	},
	{ 0xA012, "Mobile GMA3150"	},
	{ 0x2772, "Desktop GMA950"	},
  { 0x29C2, "Desktop GMA3100"	},
//	{ 0x2776, "Desktop GMA950"	}, //not a GPU
//	{ 0xA001, "Desktop GMA3150" },
	{ 0xA001, "Mobile GMA3150"	},
	{ 0xA002, "Desktop GMA3150" },
	{ 0x2A02, "GMAX3100"		},
//	{ 0x2A03, "GMAX3100"		},//not a GPU
	{ 0x2A12, "GMAX3100"		},
//	{ 0x2A13, "GMAX3100"		},
	{ 0x2A42, "GMAX3100"		},
//	{ 0x2A43, "GMAX3100"		},
  { 0x0046, "Intel HD Graphics"  },
  { 0x0102, "Intel HD Graphics 2000"  },
  { 0x0106, "Intel HD Graphics 3000"  },
  { 0x0112, "Intel HD Graphics 2000"  },
  { 0x0116, "Intel HD Graphics 3000"  },
  { 0x0122, "Intel HD Graphics 3000"  },
  { 0x0126, "Intel HD Graphics 3000"  },
  { 0x0162, "Intel HD Graphics 4000"  },  //Desktop
  { 0x0166, "Intel HD Graphics 4000"  }, // MacBookPro10,1 have this string as model name whatever chameleon team may say
  { 0x0152, "Intel HD Graphics 4000"  },  //iMac
  { 0x0156, "Intel HD Graphics 4000"  },  //MacBook
  { 0x016a, "Intel HD Graphics P4000" },  //Xeon E3-1245
  { 0x0412, "Intel HD Graphics 4600"  },  //Haswell
  { 0x0416, "Intel HD Graphics 4600"  },  //Haswell
  { 0x0A26, "Intel HD Graphics 5000"  },  //Haswell
};

CHAR8 *get_gma_model(UINT16 id) {
	INT32 i = 0;
	
	for (i = 0; i < (sizeof(KnownGPUS) / sizeof(KnownGPUS[0])); i++)
	{
		if (KnownGPUS[i].device == id)
			return KnownGPUS[i].name;
	}
	return KnownGPUS[0].name;
}

BOOLEAN setup_gma_devprop(pci_dt_t *gma_dev)
{
	CHAR8					*devicepath;
  DevPropDevice *device;
//	UINT8         *regs;
  UINT32        DualLink;
//	UINT32				bar[7];
	CHAR8					*model;
	UINT8 BuiltIn =		0x00;
  UINTN j;
  INT32 i;
	UINT8 ClassFix[4] =	{ 0x00, 0x00, 0x03, 0x00 };
  BOOLEAN Injected = FALSE;
//  UINT8 IG_ID[4] = { 0x00, 0x00, 0x62, 0x01 };
  
	devicepath = get_pci_dev_path(gma_dev);
	
//	bar[0] = pci_config_read32(gma_dev, PCI_BASE_ADDRESS_0);
//	gma_dev->regs = (UINT8 *) (UINTN)(bar[0] & ~0x0f);
	
	model = get_gma_model(gma_dev->device_id);
  for (j = 0; j < NGFX; j++) {    
    if ((gGraphics[j].Vendor == Intel) &&
        (gGraphics[j].DeviceID == gma_dev->device_id)) {
      model = gGraphics[j].Model; 
      break;
    }
  }
//	DBG("Finally model=%a\n", model);
	
	DBG("Intel %a [%04x:%04x] :: %a\n",
			model, gma_dev->vendor_id, gma_dev->device_id, devicepath);
	
	if (!string)
		string = devprop_create_string();
	
	//device = devprop_add_device(string, devicepath); //AllocatePool inside
	device = devprop_add_device_pci(string, gma_dev);
	
	if (!device) {
		DBG("Failed initializing dev-prop string dev-entry.\n");
		//pause();
		return FALSE;
	}

  for (i = 0; i < gSettings.NrAddProperties; i++) {
    if (gSettings.AddProperties[i].Device != DEV_INTEL) {
      continue;
    }
    Injected = TRUE;
    devprop_add_value(device,
                      gSettings.AddProperties[i].Key,
                      (UINT8*)gSettings.AddProperties[i].Value,
                      gSettings.AddProperties[i].ValueLen);
  }
  if (Injected) {
    DBG("custom IntelGFX properties injected, continue\n");
  }
  if (gSettings.FakeIntel) {
    UINT32 FakeID = gSettings.FakeIntel >> 16;
    devprop_add_value(device, "device-id", (UINT8*)&FakeID, 4);
    FakeID = gSettings.FakeIntel & 0xFFFF;
    devprop_add_value(device, "vendor-id", (UINT8*)&FakeID, 4);
  }
    
  if (gSettings.NoDefaultProperties) {
    DBG("Intel: no default properties\n");
    return TRUE;
  }

  DualLink = gSettings.DualLink;
                                  
  if (gSettings.InjectEDID) {
    devprop_add_value(device, "AAPL00,override-no-connect", gSettings.CustomEDID, 128);
  }
  
  devprop_add_value(device, "model", (UINT8*)model, (UINT32)AsciiStrLen(model));
	devprop_add_value(device, "device_type", (UINT8*)"display", 7);	
  devprop_add_value(device, "subsystem-vendor-id", GMAX3100_vals[21], 4);
  devprop_add_value(device, "hda-gfx", (UINT8*)"onboard-1", 10);
  switch (gma_dev->device_id) {
    case 0x0102: 
      devprop_add_value(device, "class-code",	ClassFix, 4);
    case 0x0106:
    case 0x0112:  
    case 0x0116:
    case 0x0122:
    case 0x0126:
//      if ((gma_dev->device_id == 0x112) || (gma_dev->device_id == 0x122))
//        devprop_add_value(device, "device-id", FakeID_126, 4);
    case 0x0152:
    case 0x0156:
    case 0x0162:
    case 0x0166:
    case 0x016a:
    case 0x0412:
    case 0x0416:
      if (!gSettings.IgPlatform) {
        if ((gma_dev->device_id == 0x162) ||
            (gma_dev->device_id == 0x16a)) {
          devprop_add_value(device, "AAPL,ig-platform-id", GMAX3100_vals[23], 4);
          devprop_add_value(device, "class-code",	ClassFix, 4);
        }
        else if (gma_dev->device_id == 0x166)
          devprop_add_value(device, "AAPL,ig-platform-id", GMAX3100_vals[25], 4);
        else if (gma_dev->device_id == 0x152)
          devprop_add_value(device, "AAPL,ig-platform-id", GMAX3100_vals[24], 4);
        else if (gma_dev->device_id == 0x156)
          devprop_add_value(device, "AAPL,ig-platform-id", GMAX3100_vals[25], 4);
        else if (gma_dev->device_id == 0x412)
          devprop_add_value(device, "AAPL,ig-platform-id", GMAX3100_vals[26], 4);
        else if (gma_dev->device_id == 0x416)
          devprop_add_value(device, "AAPL,ig-platform-id", GMAX3100_vals[26], 4);

        /*    IG_ID[0] = gma_dev->revision;
         IG_ID[2] |= gma_dev->device_id & 0x0f;

         devprop_add_value(device, "AAPL,ig-platform-id", IG_ID, 4); */
      } else {
        devprop_add_value(device, "AAPL,ig-platform-id", (UINT8*)&gSettings.IgPlatform, 4);
      }

    case 0xA011:
    case 0xA012:  
      if (DualLink != 0) {
        devprop_add_value(device, "AAPL00,DualLink", (UINT8*)&DualLink, 1);
      }
    case 0x2582:
    case 0x2592:
    case 0x27A2:
    case 0x27AE:
      devprop_add_value(device, "AAPL,HasPanel", reg_TRUE, 4);
      devprop_add_value(device, "built-in", &BuiltIn, 1);      
      break;
    case 0x2772:
    case 0x29C2:  
    case 0x0044:  
    case 0x0046: 
    case 0xA002:  
      devprop_add_value(device, "built-in", &BuiltIn, 1);
      devprop_add_value(device, "AAPL00,DualLink", (UINT8*)&DualLink, 1);
      break;
    case 0x2A02:
    case 0x2A12:
    case 0x2A42:
      devprop_add_value(device, "AAPL,HasPanel", GMAX3100_vals[0], 4);
      devprop_add_value(device, "AAPL,SelfRefreshSupported", GMAX3100_vals[1], 4);
      devprop_add_value(device, "AAPL,aux-power-connected", GMAX3100_vals[2], 4);
      devprop_add_value(device, "AAPL,backlight-control", GMAX3100_vals[3], 4);
      devprop_add_value(device, "AAPL00,blackscreen-preferences", GMAX3100_vals[4], 4);
      devprop_add_value(device, "AAPL01,BacklightIntensity", GMAX3100_vals[5], 4);
      devprop_add_value(device, "AAPL01,blackscreen-preferences", GMAX3100_vals[6], 4);
      devprop_add_value(device, "AAPL01,DataJustify", GMAX3100_vals[7], 4);
     // devprop_add_value(device, "AAPL01,Depth", GMAX3100_vals[8], 4);
      devprop_add_value(device, "AAPL01,Dither", GMAX3100_vals[9], 4);
      devprop_add_value(device, "AAPL01,DualLink", (UINT8 *)&DualLink, 1);
     // devprop_add_value(device, "AAPL01,Height", GMAX3100_vals[10], 4);
      devprop_add_value(device, "AAPL01,Interlace", GMAX3100_vals[11], 4);
      devprop_add_value(device, "AAPL01,Inverter", GMAX3100_vals[12], 4);
      devprop_add_value(device, "AAPL01,InverterCurrent", GMAX3100_vals[13], 4);
      //		devprop_add_value(device, "AAPL01,InverterCurrency", GMAX3100_vals[15], 4);
      devprop_add_value(device, "AAPL01,LinkFormat", GMAX3100_vals[14], 4);
      devprop_add_value(device, "AAPL01,LinkType", GMAX3100_vals[15], 4);
      devprop_add_value(device, "AAPL01,Pipe", GMAX3100_vals[16], 4);
     // devprop_add_value(device, "AAPL01,PixelFormat", GMAX3100_vals[17], 4);
      devprop_add_value(device, "AAPL01,Refresh", GMAX3100_vals[18], 4);
      devprop_add_value(device, "AAPL01,Stretch", GMAX3100_vals[19], 4);
      devprop_add_value(device, "AAPL01,InverterFrequency", GMAX3100_vals[20], 4);
      //		devprop_add_value(device, "class-code",						ClassFix, 4);
//      devprop_add_value(device, "subsystem-vendor-id", GMAX3100_vals[21], 4);
      devprop_add_value(device, "subsystem-id", GMAX3100_vals[22], 4);
      devprop_add_value(device, "built-in", &BuiltIn, 1);
      break;
    default:
      DBG("Intel card id=%x unsupported, please report to projectosx\n", gma_dev->device_id);
      return FALSE;
  }
#if DEBUG_GMA == 2  
	gBS->Stall(5000000);
#endif  

	
	return TRUE;
}
