import React from 'react'
import ReactDOM from 'react-dom'
import { Router, Route } from 'react-router';
import ReactRouterRelay from 'react-router-relay'
import Relay from 'react-relay'

Relay.injectNetworkLayer(
  new Relay.DefaultNetworkLayer('http://localhost:8081/graphql')
)

// Route components
import App from './components/app'
import PostsIndex from './components/posts_index'
const DraftsIndex = require('./components/drafts_index')
const Post = require('./components/Post')
const PostEdit = require('./components/post_edit')
const NewPost = require('./components/new_post')
const Search = require('./components/Search')

const ViewerQueries = {
  viewer: () => Relay.QL`query { viewer }`
}

const NodeQuery = {
  node: () => Relay.QL`query { node(id: $id) }`
}

const ViewerNodeQuery = {
  viewer: () => Relay.QL`query { viewer }`,
  node: () => Relay.QL`query { node(id: $id) }`
}


// Setup stores
//require('./stores/post_store');
//require('./stores/drafts_store')
//require('./stores/location')

const postOnEnter = (nextState, transition) =>
  nextState.location.query = {
    id: btoa('Post:' + nextState.params.post_id)
  };

ReactDOM.render((
  <Router createElement={ReactRouterRelay.createElement}>
    <Route queries={ViewerQueries} component={App}>
      <Route path='/' queries={ViewerQueries} component={PostsIndex} />
      <Route path="/posts/new" queries={ViewerQueries} component={NewPost} />
      <Route path='/posts/:post_id' queryParams={['id']} queries={NodeQuery} onEnter={postOnEnter} component={Post} />
      <Route path='/posts/:post_id/edit' queryParams={['id']} queries={ViewerNodeQuery} onEnter={postOnEnter} component={PostEdit} />
      <Route path="/drafts" queries={ViewerQueries} component={DraftsIndex} />
      <Route path="/search" queries={ViewerQueries} component={Search} />
    </Route>
  </Router>
), document.getElementById('mount-point'))


      //<Route path="/posts/new" component={NewPost} />
      //<Route path="/posts/:postId" component={Post} />
      //<Route path="/styleguide" component={Styleguide} />
