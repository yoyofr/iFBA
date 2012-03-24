BEGIN {
  readflag=0;
  gameNames="";
  gameId=0;
}
/^\$\<a/ {
  if (readflag==1) {
    split($0,url_tab,"\"");    
  	url_tmp=substr(url_tab[2],1,length(url_tab[2]));
  	split(url_tmp,url_tmp_tab,"&");
  	info="";
  	for (i=1; i<length(url_tmp_tab);i++) {
  		if (i>1) info=info "&" url_tmp_tab[i];
  		else info= url_tmp_tab[i];
  	}
  }
}
/^\$end/ {
	readflag=0;
	split(gameNames,listGame,",");
	for (game in listGame)  {
		if (listGame[game]) print gameId "%%name%%" listGame[game];
	}
	print gameId "%%info%% " info;
	gameId=gameId+1;
}
// {	
	if (readflag==2) {
		info= info substr($0,1,length($0)-1) "\\n";
	}
}
/^\$bio/ {
	if (readflag==1) readflag=2;
}
/^\$info/ {
	readflag=1;
	gameNames=substr($2,1,length($2)-1);
	info="";
}

END {
}
