$('body').dropArea()

$('body').on 'drop', (e) ->
  e.preventDefault()
  e = e.originalEvent

  # Check if we're on a post editing page, otherwise ignore.
  console.log $('.body textarea').length
  if $('.body textarea').length > 0
    files = e.dataTransfer.files
    for file in files
      createAttachment(file)

createAttachment = (file) ->
  uid  = ['kylemathews', (new Date).getTime(), 'raw'].join('-');
  console.log uid

  data = new FormData();

  data.append('attachment[name]', file.name);
  data.append('attachment[file]', file);
  data.append('attachment[uid]',  uid);

  $.ajax({
    url: '/attachments',
    data: data,
    cache: false,
    contentType: false,
    processData: false,
    type: 'POST',
  }).error( (error) ->
    console.log 'error uploading', error
  )

  attachmentText = "![#{ file.name }](/attachments/#{ uid })"
  $('.body textarea').insertAtCaret(attachmentText + "\n\n")
