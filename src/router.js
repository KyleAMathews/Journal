import React from 'react'
import ReactDOM from 'react-dom'
import createBrowserHistory from 'history/lib/createBrowserHistory'
import { Route, IndexRoute } from 'react-router';
import {RelayRouter} from 'react-router-relay'
import Relay from 'react-relay'

Relay.injectNetworkLayer(
  new Relay.DefaultNetworkLayer('http://localhost:8081/graphql')
)

// Route components
import App from './components/app'
import PostsIndex from './components/posts_index'
import Post from './components/Post'
import PostEdit from './components/post_edit'
import NewPost from './components/new_post'
import Drafts from './components/DraftsIndex'
import Search from './components/Search'

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

const postOnEnter = (nextState, transition) =>
  nextState.location.query = {
    id: btoa('Post:' + nextState.params.post_id)
  };

const history = createBrowserHistory()
const routes = (
  <Route path="/" queries={ViewerQueries} component={App}>
    <IndexRoute queries={ViewerQueries} component={PostsIndex} />
    <Route path="/posts/new" queries={ViewerQueries} component={NewPost} />
    <Route path='/posts/:post_id' queryParams={['id']} queries={NodeQuery} onEnter={postOnEnter} component={Post} />
    <Route path='/posts/:post_id/edit' queryParams={['id']} queries={ViewerNodeQuery} onEnter={postOnEnter} component={PostEdit} />
    <Route path="/drafts" queries={ViewerQueries} component={Drafts} />
    <Route path="/search" queries={ViewerQueries} component={Search} />
  </Route>
)

ReactDOM.render(
  <RelayRouter history={history} routes={routes}/>,
  document.getElementById('mount-point')
)
