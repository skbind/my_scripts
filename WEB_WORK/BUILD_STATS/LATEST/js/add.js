function rewritePage(form) {
    // accumulate HTML content for new page
    var newPage = "<html>\n<head>\n<title>Page for ";
    newPage += form.entry.value;
    newPage += "</title>\n</head>\n<body bgcolor='cornflowerblue'>\n";
    newPage += "<h1>Hello, " + form.entry.value + "!</h1>\n";
    newPage += "</body>\n</html>";
    // write it in one blast
    parent.instrux.document.write(newPage);
    // close writing stream
    parent.instrux.document.close( );
}