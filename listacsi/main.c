/* (c) 2016 Thomas Bernard */
/* Atari ACSI device scanning program */
#include <mint/osbind.h> 
#include <string.h>

#include "acsi.h"
#include "translated.h"
#include "gemdos.h"

/* Prototypes */
static BYTE findDevice(void);
static void getDriveConfig(void);
static int getConfig(void); 
static BYTE ce_identify(BYTE id);

/* global variables */
BYTE deviceID;

BYTE commandShort[CMD_LENGTH_SHORT]	= {			0, 'C', 'E', HOSTMOD_TRANSLATED_DISK, 0, 0};
BYTE commandLong[CMD_LENGTH_LONG]	= {0x1f,	0, 'C', 'E', HOSTMOD_TRANSLATED_DISK, 0, 0, 0, 0, 0, 0, 0, 0}; 

DWORD myBuffer[512];
BYTE *pBuffer;

#define HOSTMOD_CONFIG				1
#define HOSTMOD_LINUX_TERMINAL		2
#define HOSTMOD_TRANSLATED_DISK		3
#define HOSTMOD_NETWORK_ADAPTER		4
#define HOSTMOD_FDD_SETUP           5

#define TRAN_CMD_IDENTIFY           0
#define TRAN_CMD_GETDATETIME        1

#define DATE_OK                              0
#define DATE_ERROR                           2
#define DATE_DATETIME_UNKNOWN                4

#define Clear_home()    (void)Cconws("\33E")

WORD ceTranslatedDriveMap;

extern WORD _installed;
extern WORD _vblskipscreen;
extern WORD _vblskipconfig;

const char *version = __DATE__; 

/*--------------------------------------------------*/
int main(void)
{
	void *OldSP;

	pBuffer = (BYTE *)myBuffer;
	OldSP = (void *) Super((void *)0);  /* supervisor mode */ 
  
	/*Clear_home();*/

	(void) Cconws("\33p[ nanard ACSI test :) ]\r\n[ ver "); 
    (void) Cconws(version);
    (void) Cconws(" ]\33q\r\n"); 		
    WORD currentDrive = Dgetdrv();	/* get the current drive from system */ 
	(void)Cconws("Current Drive : ");
	Cconout('A' + currentDrive);
	(void)Cconws("\r\n");

	/* search for device on the ACSI bus */
	deviceID = findDevice();
	if (deviceID == (BYTE)-1) {
    	(void) Cconws("Quit."); 		
	    Super((void *)OldSP);  			      /* user mode */
		return 0;
	}
	/* ----------------- */

	/* now set up the acsi command bytes so we don't have to deal with this one anymore */
	commandShort[0] = (deviceID << 5); 					/* cmd[0] = ACSI_id + TEST UNIT READY (0)	*/
	
	commandLong[0] = (deviceID << 5) | 0x1f;			/* cmd[0] = ACSI_id + ICD command marker (0x1f)	*/
	commandLong[1] = 0xA0;								/* cmd[1] = command length group (5 << 5) + TEST UNIT READY (0) */ 	

    getDriveConfig();                                     /* get translated disk configuration */ 
    if(ceTranslatedDriveMap & (1 << currentDrive)) { /* did we start from translated drive? */ 
        (void)Cconws("Start from a Translated Drive\r\n");
	}

    (void)Cconin();
	
    Super((void *)OldSP);  			      			/* user mode */

	return 0;
}
/*--------------------------------------------------*/
BYTE ce_identify(BYTE ACSI_id)
{
  WORD res;
  BYTE cmd[] = {0, 'C', 'E', HOSTMOD_TRANSLATED_DISK, TRAN_CMD_IDENTIFY, 0};
  
  cmd[0] = (ACSI_id << 5); 					/* cmd[0] = ACSI_id + TEST UNIT READY (0)	*/
  memset(pBuffer, 0, 512);              	/* clear the buffer */

  res = acsi_cmd(1, cmd, 6, pBuffer, 1);	/* issue the identify command and check the result */
    
  if(res != OK)                         	/* if failed, return FALSE */
    return 0;

  (void)Cconws("\r\n  ");
  (void)Cconws((const char *)pBuffer); 
  if(strncmp((char *) pBuffer, "CosmosEx translated disk", 24) != 0) {		/* the identity string doesn't match? */
	 return 0;
  }
	
  return 1;                             /* success */
}

/*--------------------------------------------------*/
void scan_device(BYTE id)
{
	int i;
	BYTE cmd[CMD_LENGTH_SHORT] = {0,0,0,0,0,0};

	cmd[0] = id << 5;	/* TEST UNIT READY */
	memset(pBuffer, 0, 512);
	if(acsi_cmd(1, cmd, 6, pBuffer, 1) != OK)
		return;
	Cconout(' ');

	cmd[0] = (id << 5) | 0x12;	/* INQUIRY */
	cmd[4] = 0xff;
	memset(pBuffer, 0, 512);
	if(acsi_cmd(1, cmd, 6, pBuffer, 1) != OK) {
		(void)Cconws(" ***INQUIRY ERROR***");
		return;
	}
	/* http://www.tldp.org/HOWTO/archived/SCSI-Programming-HOWTO/SCSI-Programming-HOWTO-9.html
	 * offset length
	 *      0      1   type
	 *      1      1      ?
	 *      2      1 SCSI v
	 *      3      1      ?
	 *      4      4      ?
	 *      8      8 vendor
	 *     16     16  Model
	 *     32      4    Rev
	 */
	/*(void)Cconws(pBuffer + 8);*/
	for(i = 8; i < 36; i++) {
		Cconout(pBuffer[i] <= 32 ? '.' : pBuffer[i]);
	}
	(void)Cconws(" SCSI v");
	Cconout('0' + pBuffer[2]);
	Cconout(' ');
	Cconout('0' + pBuffer[0]);
}


/*--------------------------------------------------*/
BYTE findDevice()
{
	BYTE i;
	BYTE res;
	BYTE id = 0;

	(void)Cconws("Scanning ACSI devices :\r\n");

	for(;;) {
		(void)Cconws("ID.vendor.======model=====-rev\r\n");
		for(i=0; i<8; i++) {
			Cconout('0' + i);
		      
			scan_device(i);
			res = ce_identify(i);      					/* try to read the IDENTITY string */
			(void) Cconws("\r\n"); 
      
			if(res == 1) {                           	/* if found the CosmosEx */
				id = i;                     		/* store the ACSI ID of device */
			}
		}
  
		if(res == 1) {                             		/* if found, break */
			break;
		}
      
		(void)Cconws("CosmosEx Not found.\r\nPress any key to retry or 'Q' to quit.\r\n");
		if(((Cnecin() & 0xff) | 0x20) == 'q') {
			return -1;
		}
	}
  
	(void)Cconws("\r\nCosmosEx ACSI ID: ");
	Cconout('0' + id);
	(void)Cconws("\r\n\r\n");
	return id;
}

void getDriveConfig(void)
{
    getConfig();
    ceTranslatedDriveMap = pBuffer[0]<<8|pBuffer[1];
}

int getConfig(void)
{
    WORD res;
    
	commandShort[0] = (deviceID << 5); 					                        // cmd[0] = ACSI_id + TEST UNIT READY (0)
	commandShort[4] = GD_CUSTOM_getConfig;
  
	res = acsi_cmd(ACSI_READ, commandShort, CMD_LENGTH_SHORT, pBuffer, 1);		// issue the command and check the result
    
    if(res != OK) {                                                             // failed to get config?
        return -1;
    }
	return 0;
} 

