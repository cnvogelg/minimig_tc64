#include "errors.h"
#include "hardware.h"
#include "mmc.h"
#include "fat.h"
#include "osd.h"
#include "fpga.h"
#include "fdd.h"
#include "hdd.h"
#include "firmware.h"
#include "menu.h"
#include "config.h"


configTYPE config;
fileTYPE file;
extern char s[40];
char configfilename[12];

char UploadKickstart(char *name)
{
    char filename[12];
    strncpy(filename, name, 8); // copy base name
    strcpy(&filename[8], "ROM"); // add extension

    if (FileOpen(&file, filename))
    {
        if (file.size == 0x80000)
        { // 512KB Kickstart ROM
            BootPrint("Uploading 512 KB Kickstart...");
            BootUpload(&file, 0xF8, 0x08);
            return(1);
        }
        else if (file.size == 0x40000)
        { // 256KB Kickstart ROM
            BootPrint("Uploading 256 KB Kickstart...");
            BootUpload(&file, 0xF8, 0x04);
            return(1);
        }
        else
        {
            BootPrint("Unsupported ROM file size!");
        }
    }
    else
    {
        sprintf(s, "No \"%s\" file!", filename);
        BootPrint(s);
    }
    return(0);
}


char UploadActionReplay()
{
    if (FileOpen(&file, "AR3     ROM"))
    {
        if (file.size == 0x40000)
        { // 256 KB Action Replay 3 ROM
            BootPrint("\nUploading Action Replay ROM...");
            BootUpload(&file, 0x40, 0x04);
            ClearMemory(0x440000, 0x40000);
			return(1);
        }
        else
        {
            BootPrint("\nUnsupported AR3.ROM file size!!!");
			/* FatalError(6); */
			return(0);
        }
    }
}


void SetConfigurationFilename(int config)
{
	if(config)
		sprintf(configfilename,"MINIMIG%dCFG",config);
	else
		strcpy(configfilename,"MINIMIG CFG");
}


unsigned char LoadConfiguration(char *filename)
{
    static const char config_id[] = "MNMGCFG0";
	char updatekickstart=0;
	char result=0;

	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.

    // load configurastion data
    if (FileOpen(&file, filename))
    {
		BootPrint("Opened configuration file\n");
        printf("Configuration file size: %lu\r", file.size);
        if (file.size == sizeof(config))
        {
            FileRead(&file, sector_buffer);

			configTYPE *tmpconf=(configTYPE *)&sector_buffer;

            // check file id and version
            if (strncmp(tmpconf->id, config_id, sizeof(config.id)) == 0)
            {
				// A few more sanity checks...
				if(tmpconf->hardfile[0].enabled<7 && tmpconf->hardfile[1].enabled<7 && tmpconf->floppy.drives<=4) 
				{
					if(strcmp(tmpconf->kickstart.name,config.kickstart.name)!=0)
						updatekickstart=true;
	                memcpy((void*)&config, (void*)sector_buffer, sizeof(config));
					result=1; // We successfully loaded the config.
				}
				else
					BootPrint("Config file sanity check failed!\n");
            }
            else
                BootPrint("Wrong configuration file format!\n");
        }
        else
            printf("Wrong configuration file size: %lu (expected: %u)\r", file.size, sizeof(config));
    }
    else
	{
        BootPrint("Can not open configuration file!\n");

		BootPrint("Setting config defaults\n");

		WaitTimer(5000);

		// set default configuration
		memset((void*)&config, sizeof(config), 0);
		strncpy(config.id, config_id, sizeof(config.id));
		strncpy(config.kickstart.name, "KICK    ", sizeof(config.kickstart.name));
		config.kickstart.long_name[0] = 0;
		config.memory = 0x15;
		config.cpu = 0;
		config.hardfile[0].enabled = 1;
		strncpy(config.hardfile[0].name, "HARDFILE", sizeof(config.hardfile[0].name));
		config.hardfile[1].enabled = 2;	// Default is access to entire SD card
		updatekickstart=true;
	}

	// If either the old config and new config have a different kickstart file,
	// or this is the first boot, we need to upload a kickstart image.
	if(updatekickstart)
	{
		ConfigChipset(config.chipset | CONFIG_TURBO); // set CPU in turbo mode
		ConfigFloppy(1, CONFIG_FLOPPY2X); // set floppy speed
		OsdReset(RESET_BOOTLOADER);

		if (!UploadKickstart(config.kickstart.name))
		{
		    strcpy(config.kickstart.name, "KICK    ");
		    if (!UploadKickstart(config.kickstart.name))
		        FatalError(6);
		}

		if (!CheckButton() && !config.disable_ar3) // if menu button pressed don't load Action Replay
		{
			UploadActionReplay();
		}
	}

	// Whether or not we uploaded a kickstart image we now need to set various parameters from the config.

   	OpenHardfile(0);
   	OpenHardfile(1);

    ConfigIDE(config.enable_ide, config.hardfile[0].present && config.hardfile[0].enabled, config.hardfile[1].present && config.hardfile[1].enabled);
    WaitTimer(1000);

    printf("Bootloading is complete.\r");

    BootPrint("\nExiting bootloader...");
    WaitTimer(500);

    ConfigMemory(config.memory);
    ConfigCPU(config.cpu);
    ConfigFloppy(config.floppy.drives, config.floppy.speed);

    BootExit();

    ConfigChipset(config.chipset);
    ConfigFilter(config.filter.lores, config.filter.hires);
    ConfigScanlines(config.scanlines);

    return(result);
}


unsigned char SaveConfiguration(char *filename)
{
	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.

    // save configuration data
    if (FileOpen(&file, filename))
    {
        printf("Configuration file size: %lu\r", file.size);
        if (file.size != sizeof(config))
        {
            file.size = sizeof(config);
            if (!UpdateEntry(&file))
                return(0);
        }

        memset((void*)&sector_buffer, 0, sizeof(sector_buffer));
        memcpy((void*)&sector_buffer, (void*)&config, sizeof(config));
        FileWrite(&file, sector_buffer);
        return(1);
    }
    else
    {
        printf("Configuration file not found!\r");
        printf("Trying to create a new one...\r");
        strncpy(file.name, filename, 11);
        file.attributes = 0;
        file.size = sizeof(config);
        if (FileCreate(0, &file))
        {
            printf("File created.\r");
            printf("Trying to write new data...\r");
            memset((void*)sector_buffer, 0, sizeof(sector_buffer));
            memcpy((void*)sector_buffer, (void*)&config, sizeof(config));

            if (FileWrite(&file, sector_buffer))
            {
                printf("File written successfully.\r");
                return(1);
            }
            else
                printf("File write failed!\r");
        }
        else
            printf("File creation failed!\r");
    }
    return(0);
}

