for my $browser(qw/ie mozilla/) {
close(STDOUT);
open(STDOUT, ">$browser.pm");
print "package $browser;\n";
print q`
# NOTE -- This file is generated by running make-js-interfaces.pl
use default;
@ISA = qw/default/;

sub new {
   my($self,$event) = @_;
   $event->add('user add', code => \&useradd);
   $event->add('user del', code => \&userdel);
   $event->add('user change nick', code => \&usernick);
   $event->add('user change', code => \&usermode);
   $self->add('Status', 0);
   return bless {};
}

sub _out {
   print "<script>$_[0]</script>\r\n";
}

sub _func_out {
   my($func,@rest) = @_;
   @rest = map(ref $_ eq 'ARRAY' ? _outputarray($_) : _escapejs($_), @rest);
   _out('parent.' . $func . '(' . _jsp(@rest) . ');');
}

sub _escapejs {
   my $in = shift;
   $in =~ s/\\\\/\\\\\\\\/g;
   $in =~ s/'/\\\\'/g;
   return '\'' . $in . '\'';
}

sub _jsp {
   return join(', ', @_);
}

sub _outputarray {
   my $array = shift;
   return '[' . _jsp(map(_escapejs($_), @$array)) . ']';
}

sub useradd {
   my($event, $nicks, $channel) = @_;
   _func_out('channeladdusers', $channel, $nicks);
}

sub userdel {
   my($event, $nick, $channels) = @_;
   _func_out('channelsdeluser', $channels, $nick);
}

sub usernick {
   my($event,$old,$new,$channels) = @_;
   _func_out('channelsusernick', $old, $new);
}

sub usermode {
   my($event,$nick, $channel, $action, $type) = @_;
   _func_out('channelusermode', $channel, $nick, $action, $type);
}

sub exists {
   return 1 if defined &{__PACKAGE__ . '::' . $_[1]};
}

sub line {
   my($self, $info, $html) = @_;
   my $target = defined $info->{target} ? $info->{target} : 'Status';

   if(ref $target eq 'ARRAY') {
      my %tmp = %$info;
	  for(@$target) {
	     $tmp{target} = $_;
         $self->line(\%tmp, $html);
	  }
	  return;
   }

   if(not exists $self->{lc $target}) {
      if(defined $info && ref $info && exists $info->{create} && $info->{create}) {
	     $self->add($target, $info->{type} eq 'join' ? 1 : 0);
	  }elsif($target ne '-all') {
         $target = 'Status';
	  }
   }
   _func_out('witemaddtext', $target, $html . '<br>', $info->{activity} || 0);
}

sub error {
   my($self,$message) = @_;
   $self->line({ target => 'Status'}, $message);
}

sub add {
   my($self,$add,$channel) = @_;
   return if not defined $add;
   $self->{lc $add}++;
   _func_out('witemadd', $add, $channel);
   _func_out('witemchg', $add) if $channel;
}

sub frameset {
   my($self, $scriptname, $config, $random, $out, $interface) = @_;
print <<EOF;
<html>

<head>
<title>CGI:IRC</title>
</head>

<frameset rows="40,*,25,0" framespacing="0" border="0" frameborder="0">
<frame name="fwindowlist" src="$scriptname?$out&item=fwindowlist" scrolling="no">
<frameset cols="*,100" framespacing="0" border="0" frameborder="0">
<frame name="fmain" src="$scriptname?item=fmain&interface=$interface" scrolling="yes">
<frame name="fuserlist" src="$scriptname?item=fuserlist&interface=$interface" scrolling="no">
</frameset>
<frame name="fform" src="$scriptname?item=fform&interface=$interface" scrolling="no">
<frame name="hiddenframe" src="about:blank" scrolling="no">
<noframes>
This interface requires a browser that supports frames and javascript.
</noframes>

</frameset>
</html>
EOF
}

sub fuserlist {
print <<EOF;
<html>
<head>
<style><!--
BODY { border-left: 1px solid #999999; margin: 0; }
SELECT { border: 0; padding: 0;width: 100%; height: 100%; }
// -->
</style>
</head>
<body>
<form name="mform">
<select size="2" name="userlist">
</select>
</form>
</body>
</html>
EOF
}

sub fmain {
print <<EOF;
<html><head></head>
<body>
`;
if($browser eq 'ie') {
   print q`<span id="text"></span>`;
}else{
   print q`<span name="text"></span>`;
}
print q`
</body></html>
EOF
}

sub say {
   my($self) = @_;
   return 'ok';
}

sub fform {
print <<EOF;
<html>
<head>
<html><head>
<script><!--
var history = [ ];
var hispos;
var tabtmp = [ ];
var tabpos;
var tablen;
var tabinc;

function fns(){
   if(!document.myform["say"]) return;
   document.myform["say"].focus();
}

function t(item,text) {
   if(item.style.display == 'none') {
      item.style.display = 'inline';
	  text.value = '>';
   }else{
      item.style.display = 'none';
	  text.value = '<';
   }
   fns();
}

function load() {
   extra.style.display = 'none';
   fns();
}

function append(a) {
   document.myform["say"].value += a;
   fns();
}

function cmd() {
   if(document.myform.say.value.length < 1) return false;
   hisadd();
   tabpos = 0;
   tabtmp = [];
   parent.fwindowlist.sendcmd(document.myform.say.value);
   document.myform.say.value = ''
   return false;
}

function hisadd() {
   history[history.length] = document.myform.say.value;
   hispos = history.length;
}

function hisdo() {
   if(history[hispos]) {
      document.myform.say.value = history[hispos];
   }else{
      document.myform.say.value = '';
   }
}
`;
if($browser eq 'ie') {
print q`
document.onkeydown = function() {
   var srcEl = event.srcElement;
   if (srcEl.tagName != 'INPUT' || srcEl.name.toLowerCase() != 'say')
       return true;

   if(event.keyCode == 66 && event.ctrlKey) {
	   append('\%B');
   }else if(event.keyCode == 67 && event.ctrlKey) {
       append('\%C');
   }else if(event.keyCode == 9) { // TAB
       var tabIndex = srcEl.value.lastIndexOf(' ');
	   var tabStr = srcEl.value.substr(tabIndex+1 || tabIndex).toLowerCase();

       if(tabpos == tabIndex && !tabStr && tabtmp.length) {
	      if(tabinc >= tabtmp.length) tabinc = 0;
	      for(var i = (tabinc > 0 ? tabinc : 0); i < tabtmp.length;i++) {
			 srcEl.value = srcEl.value.substr(0, tabIndex - tablen) + 
			       tabtmp[i] + (tabIndex == tablen ? ': ' : ' ');
			 tabpos = (tabIndex == -1 ? 0 : tabIndex) + tabtmp[i].length - tablen + (tabIndex == tablen ? 1 : 0);
			 tablen = tabtmp[i].length + (tabIndex == tablen ? 1 : 0);
			 tabinc++;
			 break;
		  }
	   }else{
	      tabtmp = [];
	      var list = parent.fwindowlist.channellist(parent.fwindowlist.currentwindow);
		  for(var i = 0;i < list.length; i++) {
		     var item = list[i].replace(/^[+%@]/,'');
		     if(item.substr(0, tabStr.length).toLowerCase() == tabStr) {
			    tabtmp[tabtmp.length] = item;
			 }
		  }
		  if(!tabtmp[0]) {
		     for(var i in parent.fwindowlist.Witems) {
			    if(i.substr(0, tabStr.length).toLowerCase() == tabStr) {
				   tabtmp[tabtmp.length] = i;
				}   
			 }
		  }
		  if(!tabtmp[0]) return false;
		  srcEl.value = srcEl.value.substr(0, tabIndex) + 
		        (tabIndex > 0 ? ' ' : '') + tabtmp[0] + (tabIndex == -1 ? ': ' : ' ');
		  tablen = tabtmp[0].length + (tabIndex == -1 ? 1 : 0);
		  tabpos = (tabIndex == -1 ? 0 : tabIndex + 1) + tablen;
		  tabinc = 1;
	   }
   }else if(event.keyCode == 38) { // UP
       if(!history[hispos]) {
	      if(document.myform.say.value) hisadd();
		  hispos = history.length;
	   }
	   hispos--;
	   hisdo();
   }else if(event.keyCode == 40) { // DOWN
       if(!history[hispos]) {
	      if(document.myform.say.value) hisadd();
		  document.myform.say.value = '';
		  return false;
	   }
	   hispos++;
	   hisdo();
   }else if(event.altKey && event.keyCode > 47 && event.keyCode < 58) {
       var num = event.keyCode - 48;
	   if(num == 0) num = 10;

	   var name = parent.fwindowlist.witemchgnum(num);
	   if(!name) return false;
	   parent.fwindowlist.witemchg(name);
   }else{
       return true;
   }
   keyCode=0;
   returnValue=false;
   return false;
}
`;
}
print q`
//-->
</script>
<style><!--
BODY { border-top: 1px solid #999999;margin: 0; }
.myform { float: left; }
.say { border: 0; width: 80%; padding-left: 4px; }
.econtain { float: right; }
.extra { display: none; }
.boldbutton { font-weight: bold; }
.expand { border: 0; background: #ffffff; }
// -->
</style>
</head>
<body onload="load()" onfocus="fns()">

<form name="myform" onSubmit="return cmd();" class="myform">
<input type="text" class="say" name="say" autocomplete="off">
</form>

<span class="econtain">
<span id="extra" class="extra">
<input type="button" class="boldbutton" value="B" onclick="append('\%B')">

<select name="colour" onchange="append('\%C' + this.options[this.selectedIndex].value)">
<option></option>
<option style="color: #ff0000" value="04">red</option>
</select>

</span>
<input type="button" class="expand" onclick="t(extra,this)" value="&lt;">
</span>

</body>
</html>
EOF
}

sub fwindowlist {
   my($self, $cgi, $config) = @_;
   my $string;
   for(keys %$cgi) {
      next if $_ eq 'item';
	  $string .= main::cgi_encode($_) . '=' . main::cgi_encode($cgi->{$_}).'&';
   }
   $string =~ s/\&$//;
print q~
<html>
<head>
<style type="text/css"><!--
BODY {
   margin: 0px;
   background: #f1f1f1;
   border-bottom: 1px solid #999999;
}

.Wchooser { 
   border: 1px solid #f1f1f1;
   padding: 2px;
   margin: 2px;
}

.Wcontainer {
   width: 100%;
   height: 100%;
   padding: 5px;
}

.Wmouseover {
   background: #c0c0dd;
   border: 1px solid black;
   padding: 2px;
   margin: 2px;
}

.Wactive {
   background: #cccccc;
   border: 1px solid #999999;
   padding: 2px;
   margin: 2px;
}

.hidden {
   display: none;
}

// -->
</style>
<script>
<!--
// Set this somehow
//               none      joins    talk       directed talk
var activity = ['#000000','#000099','#990000', '#009999'];

var Witems = {};
var currentwindow = '';
var lastwindow = '';

`;
if($browser eq 'ie') {
print q`
document.onselectstart = function() { return false; }
document.onmouseup = function() {
   if(event.button != 2) return true;
   event.returnVal = false;
   return false;
}
document.oncontextmenu = function() {
   return false;
}
`;
}

print q`
function witemadd(name, channel) {
   if(Witems[name] || findwin(name)) return;
   name = name.replace(/\"/g, '&quot;');
   Witems[ name ] = { activity: 0, text: new Array, channel: channel };
   if(channel) {
      Witems[name].users = {};
	  Witems[name].topic = '';
   }
   if(!currentwindow) currentwindow = name;
   wlistredraw();
}

function witemdel(name) {
   if(!Witems[name] && !(name = findwin(name))) return;
   delete Witems[name];
}

function channeladdusers(channel, users) {
   for(var i = 0;i < users.length;i++) {
      channeladduser(channel, users[i]);
   }
}

function channeladduser(channel, user) {
   var o = user.substr(0,1);
   if(o == '@' || o == '+' || o == '%')
      user = user.substr(1);

   if(!Witems[channel] && !(channel = findwin(channel))) return;

   Witems[channel].users[user] = { };

   if(o == '@') Witems[channel].users[user].op = 1;
   if(o == '%') Witems[channel].users[user].halfop = 1;
   if(o == '+') Witems[channel].users[user].voice = 1;
   userlist();
}

function channelsdeluser(channels, user) {
   for(var i = 0;i < channels.length; i++) {
      channeldeluser(channels[i], user);
   }
   userlist();
}

function channeldeluser(channel, user) {
   if(!Witems[channel] && !(channel = findwin(channel))) return;
   delete Witems[channel].users[user];
   userlist();
}

function channelsusernick(olduser, newuser) {
   for(var channel in Witems) {
      if(!Witems[channel].channel) continue;
	  for(var nick in Witems[channel].users) {
	     if(nick == olduser) {
		    Witems[channel].users[newuser] = Witems[channel].users[olduser];
			delete Witems[channel].users[olduser];
		 }
	  }
   }
   userlist();
}

function channelusermode(channel, user, action, type) {
   if(!Witems[channel] && !(channel = findwin(channel))) return;
   if(!Witems[channel].users[user]) return;

   if(type == 'op') {
      Witems[channel].users[user].op = (action == '+' ? 1 : 0);
   }else if(type == 'voice') {
      Witems[channel].users[user].voice = (action == '+' ? 1 : 0);
   }else if(type == 'halfop') {
      Witems[channel].users[user].halfop = (action == '+' ? 1 : 0);
   }
   userlist();
}

function channellist(channel) {
   if(!Witems[channel] && !(channel = findwin(channel))) return;
   var users = new Array();

   for (var i in Witems[channel].users) {
      var user = Witems[channel].users[i];
      if(user.op) i = '@' + i
	  else if(user.halfop) i = '%' + i;
	  else if(user.voice) i = '+' + i;

      users[users.length] = i;
   }

   users = users.sort(usersort);
   return users;
}

function usersort(user1,user2) {
   var m1 = user1.substr(0,1);
   var m2 = user2.substr(0,1);

   if(m1 == m2) {
      if(user1.toUpperCase() < user2.toUpperCase()) return -1;
	  if(user2.toUpperCase() < user1.toUpperCase()) return 1;
	  return 0; // shouldn't happen :-)
   }else if(m1 == '@') {
      return -1;
   }else if(m2 == '@') {
      return 1;
   }else if(m1 == '%') {
      return -1;
   }else if(m2 == '%') {
      return 1;
   }else if(m1 == '+') {
      return -1;
   }else if(m2 == '+') {
      return 1;
   }else{
      if(user1.toUpperCase() < user2.toUpperCase()) return -1;
	  if(user2.toUpperCase() < user1.toUpperCase()) return 1;
	  return 0;
   }
}

function witemchg(name) {
   if(!Witems[name] && !(name = findwin(name))) return;
   if(Witems[name].activity > 0) Witems[name].activity = 0;
   lastwindow = currentwindow;
   currentwindow = name;
   wlistredraw();
   witemredraw();
   if(parent.fform.location) parent.fform.fns();
   userlist();
   retitle();
}

function retitle() {
   parent.document.title = 'CGI:IRC - ' + currentwindow + (Witems[currentwindow].channel == 1 ? ' [' + countit(Witems[currentwindow].users) + '] ' : '');
}

function witemchgnum(num) {
   var count = 1;
   for(var name in Witems) {
      if(count++ == num) return name;
   }
   return false;
}

function countit(obj) {
   var i = 0;
   for(var foo in obj) i++;
   return i;
}

function witemaddtext(name, text, activity) {
   if(name == '-all') {
      for(var window in Witems) {
	     witemaddtext(window, text, activity);
	  }
      return;
   }
   if(!Witems[name] && !(name = findwin(name))) {
      if(!Witems["Status"]) return;
	  name = "Status";
   }
   Witems[name].text[Witems[name].text.length] = text;
   if(currentwindow != name && activity > Witems[name].activity)
       witemact(name, activity);
   if(currentwindow == name) witemredraw();
}

function witemact(name, activity) {
   if(!Witems[name] && !(name = findwin(name))) return;
   Witems[name].activity = activity;
   wlistredraw();
}

function witemredraw() {
   if(!parent.fmain.document) {
      setTimeout("witemredraw()", 1000);
	  return;
   }
`;
if($browser eq 'ie') {
print q`
   parent.fmain.text.innerHTML = Witems[currentwindow].text.join('');

   var count = 0;
   var doc = parent.fmain.document.body;
   while(doc.scrollTop < doc.scrollHeight && count < 20) {
      doc.scrollTop = doc.scrollHeight;
      count++;
   }
`;
}else{
   print q`
   parent.frames.fmain.document.getElementsByName("text").item(0).innerHTML = Witems[currentwindow].text.join('');
   
   var doc = parent.frames.fmain.window;
   var scroll = -1;
   while(doc.scrollY > scroll) {
	  scroll = doc.scrollY;
	  doc.scrollBy(0, 500);
   }
`;
}
print q`
}

function wlistredraw() {
   var output='';
   for (var i in Witems) {
      output += '<span class="' + (i == currentwindow ? 'Wactive' : 'Wchooser') + '" style="color: ' + activity[Witems[i].activity] + ';" onclick="witemchg(\'' + (i == currentwindow ? escapejs(lastwindow) : escapejs(i)) + '\')" onmouseover="this.className = \'Wmouseover\'" onmouseout="this.className = \'' + (i == currentwindow ? 'Wactive' : 'Wchooser') + '\'">' + escapehtml(i) + '</span>\r\n';
   }
`;
if($browser eq 'ie') {
   print "windowlist.innerHTML = output;";
}else{
   print 'document.getElementsByName("windowlist").item(0).innerHTML = output;'
   
}
print q`


}

function findwin(name) {
   var wname = new String(name);
   wname = wname.replace(/\"/g, '&quot;');
   for (var i in Witems) {
      if (i.toUpperCase() == wname.toUpperCase())
	     return i;
   }
   return false;
}

function escapejs(string) {
   var out = string; // perl needs some slashes here.
   // quite mad.
   out = out.replace(/\\\\\\\\/g,'\\\\\\\\\\\\\\\\');
   out = out.replace(/\\\\'/g, '\\\\\\\\\\\\'');
   out = out.replace(/\"/g, '&quot;');
   return out;
}

function escapehtml(string) {
   var out = string;
   out = out.replace(/</g, '&lt;');
   out = out.replace(/>/g, '&gt;');
   out = out.replace(/\"/g, '&quot;');
   return out;
}

function sendcmd(cmd) {
   if(currentwindow == 'Status' && cmd.substr(0,1) != '/') return;
   document.hsubmit.say.value = cmd;
   document.hsubmit.target.value = currentwindow;
   document.hsubmit.submit();
}

function userlist() {
   if(Witems[currentwindow] && Witems[currentwindow].channel == 1) {
      userlistupdate(channellist(currentwindow));
   }else{
      userlistupdate(['No channel']);
   }
   retitle();
}

function userlistupdate(list) {
   if(!parent.fuserlist.document.mform.userlist) return;
   var sel = parent.fuserlist.document.mform.userlist;

   for(var i = sel.length;i+1 > 0;i--) {
      sel.remove(i);
   }

   for(var i = 0;i < list.length;i++) {
      var opt = parent.fuserlist.document.createElement("OPTION");
	  opt.text = list[i];
`;
if($browser eq 'ie') {
      print "sel.add(opt);\n";
}else{
      print "sel.add(opt, null);\n";
}
print q`
   }
}

// -->
</script>
</head>
<body onload="wlistredraw();">
<noscript>Scripting is required for this interface</noscript>
~;
print <<EOF;
`;
if($browser eq 'ie'){
print q`
<iframe src="$config->{script_nph}?$string" width="1" height="1" class="hidden"></iframe>
<span class="Wcontainer" id="windowlist"></span>
`;
}else{
print q`
<iframe src="$config->{script_nph}?$string" width="1" height="1"></iframe>
<span class="Wcontainer" name="windowlist"></span>
`;
}
print q`
<form name="hsubmit" class="hidden" method="post" action="$config->{script_form}" target="hiddenframe">
<input type="hidden" name="R" value="$cgi->{R}">
<input type="hidden" name="cmd" value="say">
<input type="hidden" name="s" value="say">
<input type="hidden" name="say" value="">
<input type="hidden" name="target" value="">
</form>
</body></html>
EOF
}

1;
`;
}