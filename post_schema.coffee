mongoose = require('mongoose')
mongoose.connect('mongodb://localhost/journal')

# Setup MongoDB schemas.
Schema = mongoose.Schema

PostSchema = new Schema (
  title: String
  body: String
  created: { type: Date, index: true }
  changed: { type: Date, index: true }
)

mongoose.model 'post', PostSchema
