function collection_select_changed() {
  url = removeParams();
  let select = document.getElementById('logs_collections');
  let collection = select.options[select.selectedIndex].value;
  document.location = url + '?coll=' + collection
}

function operationHandler(op) {
  document.location = appendParam('op', op);
}

function collscanHandler() {
  document.location = removeParams() + '?collscan=true';
}

function appendParam(name, value) {
  var url = new URL(document.location.toString());
  var query_string = url.search;
  var search_params = new URLSearchParams(query_string);
  search_params.append(name, value);
  url.search = search_params.toString();
  return url.toString();
}

function removeParams() {
  return document.location.toString().split('?')[0]
}
