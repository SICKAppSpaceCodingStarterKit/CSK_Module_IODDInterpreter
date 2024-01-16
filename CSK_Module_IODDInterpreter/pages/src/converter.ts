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
