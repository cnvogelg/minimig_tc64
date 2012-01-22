CHACOCMD=chacocmd

clean:
	for a in rpt summary done jdi smsg pin rbf sof ; do \
		find . -name "*.$$a" -exec rm {} \; ; \
	done
	find chameleon -mindepth 1 -type d -d -exec rm -rf {} \;
	find chameleon -name "*.txt" -exec rm {} \;

clean_bak:
	find . -type f -name '*.bak' -exec rm {} \;
	
run: flash start

flash:
	$(CHACOCMD) --flashrbf 2 chameleon/fampiga_top.rbf

start:
	$(CHACOCMD) --start 2
