void ShiftFpga(unsigned char data);
unsigned char ConfigureFpga(void);
void SendFile(fileTYPE *file);
void SendFileEncrypted(fileTYPE *file,unsigned char *key,int keysize);
char BootPrint(const char *text);
char PrepareBootUpload(unsigned char base, unsigned char size);
void BootExit(void);
void ClearMemory(unsigned long base, unsigned long size);
unsigned char GetFPGAStatus(void);
