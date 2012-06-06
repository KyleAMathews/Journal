mongoose = require('mongoose')
mongoose.connect('mongodb://localhost/journal')

# Setup MongoDB schemas.
Schema = mongoose.Schema

PostSchema = new Schema (
  title: { type: String, required: true }
  body: { type: String, required: true }
  nid: { type: Number, min: 1, required: true, index: true, unique: true }
  created: { type: Date, index: true }
  changed: { type: Date, index: true }
  deleted: { type: Boolean, default: false, index: true }
  _user: { type: Schema.ObjectId, ref: 'User', index: true }
)

mongoose.model 'post', PostSchema
