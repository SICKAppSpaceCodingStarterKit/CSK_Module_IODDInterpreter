document.addEventListener('sopasjs-ready', () => {
  const page_1 = document.querySelector('div.sopasjs-ui-navbar-wrapper > div > ul > li:nth-child(3) > a > i');
  page_1.classList.remove('fa-file');
  page_1.classList.add('fa-sort-amount-desc');

  const page_2 = document.querySelector('div.sopasjs-ui-navbar-wrapper > div > ul > li:nth-child(4) > a > i');
  page_2.classList.remove('fa-file');
  page_2.classList.add('fa-sort-amount-desc');

  const page_3 = document.querySelector('div.sopasjs-ui-navbar-wrapper > div > ul > li:nth-child(5) > a > i');
  page_3.classList.remove('fa-file');
  page_3.classList.add('fa-sort-amount-desc');

  setTimeout(() => {
    document.title = 'CSK_Module_IODDInterpreter'
  }, 500);
})