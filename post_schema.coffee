mongoose = require('mongoose')
mongoose.connect('mongodb://localhost/journal')
mongoosastic = require('mongoosastic')

# Setup MongoDB schemas.
Schema = mongoose.Schema

PostSchema = new Schema (
  title: { type: String, required: true, es_boost:2.0 }
  body: { type: String, required: true }
  nid: { type: Number, min: 1, required: true, index: true, unique: true, es_type: 'integer' }
  created: { type: Date, index: true, es_type:'date' }
  changed: { type: Date, index: true, es_type:'date' }
  deleted: { type: Boolean, default: false, index: true }
  _user: { type: Schema.ObjectId, ref: 'User', index: true }
)

PostSchema.plugin(mongoosastic, { index: 'journal_posts' })
Post = mongoose.model 'post', PostSchema
#Post.createMapping (err, mapping) ->
  #console.log err
  #console.log mapping
  #return mapping

DraftSchema = new Schema (
  title: { type: String }
  body: { type: String }
  created: { type: Date, index: true }
  changed: { type: Date, index: true }
  _user: { type: Schema.ObjectId, ref: 'User', index: true }
)

mongoose.model 'draft', DraftSchema
