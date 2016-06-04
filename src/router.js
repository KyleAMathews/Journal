import React from 'react'
import ReactDOM from 'react-dom'
import { Router, Route, IndexRoute, browserHistory, applyRouterMiddleware } from 'react-router'
import useRelay from 'react-router-relay'
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
  viewer: () => Relay.QL`query { viewer }`,
}

const NodeQuery = {
  node: () => Relay.QL`query { node(id: $id) }`,
}

const ViewerNodeQuery = {
  viewer: () => Relay.QL`query { viewer }`,
  node: () => Relay.QL`query { node(id: $id) }`,
}

const preparePostParams = (params, { location }) => {
  return {
    ...params,
    id: btoa(`Post:${params.post_id}`),
  }
}

const routes =
  (<Route
    path="/"
    queries={ViewerQueries}
    component={App}
  >
    <IndexRoute
      queries={ViewerQueries}
      component={PostsIndex}
    />
    <Route
      path="/posts/new"
      queries={ViewerQueries}
      component={NewPost}
    />
    <Route
      path="/posts/:post_id"
      queries={NodeQuery}
      prepareParams={preparePostParams}
      component={Post}
    />
    <Route
      path="/posts/:post_id/edit"
      queries={ViewerNodeQuery}
      prepareParams={preparePostParams}
      component={PostEdit}
    />
    <Route
      path="/drafts"
      queries={ViewerQueries}
      component={Drafts}
    />
    <Route
      path="/search"
      queries={ViewerQueries}
      component={Search}
    />
  </Route>)

ReactDOM.render(
  <Router
    history={browserHistory}
    render={applyRouterMiddleware(useRelay)}
    environment={Relay.Store}
    routes={routes}
  >
    {routes}
  </Router>,
  document.getElementById('mount-point')
)
