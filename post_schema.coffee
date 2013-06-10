config = require './app_config'

mongoose = require('mongoose')
mongoose.connect(config.mongo_url)
mongoosastic = require('mongoosastic')

# Setup MongoDB schemas.
Schema = mongoose.Schema

SchemaTypes = mongoose.Schema.Types
PostSchema = new Schema (
  title: { type: String, required: true, es_boost:2.0 }
  body: { type: String, required: true }
  nid: { type: Number, min: 1, required: true, index: true, unique: true, es_type: 'long' }
  created: { type: Date, index: true, es_type:'date' }
  changed: { type: Date, index: true, es_type:'date' }
  deleted: { type: Boolean, default: false, index: true, es_type: 'boolean' }
  latitude: { type: String, default: "", es_type: 'string' }
  longitude: { type: String, default: "", es_type: 'string' }
  _user: { type: Schema.ObjectId, ref: 'User', index: true }
)
PostSchema.plugin(mongoosastic, config.elasticSearchHost)
Post = mongoose.model 'post', PostSchema
#Post.createMapping (err, mapping) ->
  #console.log err
  #console.log mapping

DraftSchema = new Schema (
  title: { type: String }
  body: { type: String }
  created: { type: Date, index: true }
  changed: { type: Date, index: true }
  _user: { type: Schema.ObjectId, ref: 'User', index: true }
)

mongoose.model 'draft', DraftSchema

AttachmentSchema = new Schema (
  path: { type: String }
  pathSmall: { type: String }
  uid: { type: String, index: true }
  created: { type: Date, index: true }
  _user: { type: Schema.ObjectId, ref: 'User', index: true }
)

mongoose.model 'attachment', AttachmentSchema
