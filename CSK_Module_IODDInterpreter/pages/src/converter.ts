export function convertToList(value) {
  return JSON.parse(value)
}

export function extractFilenames(files: FileList): Array<string> {
  if(files === null || files == undefined) {
    return []
  }
  const fileNames = [];
  for (const file of files) {
    fileNames.push(file.name);
  }
  return fileNames;
}

export function bool2str(newbool){
  var myString: string = String(newbool);
  return myString
}

export function num2str(newnum){
  return String(newnum)
}

export function str2num(newstr){
  return Number(newstr)
}

export function changeStyle(theme) {
  const style: HTMLStyleElement = document.createElement('style');
  style.id ='blub'

  const toggleSW = document.querySelectorAll("davinci-toggle-switch")
  toggleSW.forEach((userItem) => {
    const shadowToggle = userItem.shadowRoot
    const finalToggleSW = shadowToggle?.querySelector('div')
    finalToggleSW?.classList.add('hasIcon')
  });

  if (theme == 'CSK_Style'){
    var headerToolbar = `.sopasjs-ui-header-toolbar-wrapper { background-color: #FFFFFF; }`
    var uiHeader = `.sopasjs-ui-header>.app-logo { margin-right:0px; }`
    var appLogo = `.app-logo { background-color:#FFFFFF; background-image: url(data:image/png;base64,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) }`
    var uiNavbar =`.sopasjs-ui-navbar-wrapper { background-color: #737F85; }`
    var navbarMenuLiActive = `.sopasjs-navbar-menu>li.active { background-color: #283c45; }`
    var navbarMenuLiActiveA = `.sopasjs-navbar-menu>li.active>a { background-color: #283c45; }`
    var navbarMeluLi = `.sopasjs-navbar-menu>li { color: #FFFFFF; }`
    var navbarMeluLiA = `.sopasjs-navbar-menu>li>a { color: #FFFFFF; }`
    var headerToolbarButtonHighlight = `.sopasjs-ui-header-toolbar-button.sopasjs-ui-navigation-navbutton>a.highlight { background-color: #737F85; }`
    var toolbarButton = `.sopasjs-ui-header-toolbar-button>a { color: #283c45; }`

    var customBackground =  `.CSK_Module_IODDInterpreter .myCustomBackground_CSK_Module_IODDInterpreter { background-color: #737F8522; }` // font-family: "Open Sans"; }`
  
    style.innerHTML = headerToolbar;
    style.innerHTML += uiHeader;
    style.innerHTML += appLogo;
    style.innerHTML += uiNavbar;
    style.innerHTML += navbarMenuLiActive;
    style.innerHTML += navbarMenuLiActiveA;
    style.innerHTML += navbarMeluLi;
    style.innerHTML += navbarMeluLiA;
    style.innerHTML += headerToolbarButtonHighlight;
    style.innerHTML += toolbarButton;

    style.innerHTML += customBackground;
  }
  else if (theme == 'None'){
    var headerToolbar = `.sopasjs-ui-header-toolbar-wrapper { background-color: #007fc3; }`
    var uiHeader = `.sopasjs-ui-header>.app-logo { margin-right:10px; }`
    var appLogo = `.app-logo { background-color:#007fc3; background-image: url('data:image/png;base64,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') }`
    var uiNavbar =`.sopasjs-ui-navbar-wrapper { background-color: #f6f8f9; }`
    var navbarMenuLiActive = `.sopasjs-navbar-menu>li.active { background-color: #007fc3; }`
    var navbarMenuLiActiveA = `.sopasjs-navbar-menu>li.active>a { background-color: #007fc3; }`
    var navbarMeluLi = `.sopasjs-navbar-menu>li { color: #697987; }`
    var navbarMeluLiA = `.sopasjs-navbar-menu>li>a { color: #505f6b; }`
    var headerToolbarButtonHighlight = `.sopasjs-ui-header-toolbar-button.sopasjs-ui-navigation-navbutton>a.highlight { background-color: #006093; }`
    var toolbarButton = `.sopasjs-ui-header-toolbar-button>a { color: #cce5f3; }`

    var customBackground =  `.CSK_Module_IODDInterpreter .myCustomBackground_CSK_Module_IODDInterpreter { background-color: #fff; }` // font-family: "sans-serif"; }`
  
    style.innerHTML = headerToolbar;
    style.innerHTML += uiHeader;
    style.innerHTML += appLogo;
    style.innerHTML += uiNavbar;
    style.innerHTML += navbarMenuLiActive;
    style.innerHTML += navbarMenuLiActiveA;
    style.innerHTML += navbarMeluLi;
    style.innerHTML += navbarMeluLiA;
    style.innerHTML += headerToolbarButtonHighlight;
    style.innerHTML += toolbarButton;

    style.innerHTML += customBackground;
  }
  document.head.append(style);
  return theme
}