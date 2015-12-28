import Relay from 'react-relay'

export default class SavePostMutation extends Relay.Mutation {
  static fragments = {
    viewer: () => Relay.QL`
      fragment on User {
        id
      }
    `,
    post: () => Relay.QL`
      fragment on Post {
        id
        title
        body
        draft
      }
    `,
  };
  getMutation() {
    return Relay.QL`mutation{savePost}`;
  }
  getFatQuery() {
    return Relay.QL`
      fragment on SavePostPayload {
        postEdge
        viewer {
          id
          allPosts
          allDrafts
        }
      }
    `;
  }
  getConfigs() {
    return [{
      type: 'FIELDS_CHANGE',
      fieldIDs: {
        viewer: this.props.viewer.id,
      }
    },
    {
      type: 'RANGE_DELETE',
      parentName: 'viewer',
      parentId: this.props.viewer.id,
      connectionname: 'allDrafts',
      deletedIDFieldName: 'postId',
      pathToConnection: ['viewer', 'allDrafts']
    },
    {
      type: 'RANGE_ADD',
      parentName: 'viewer',
      parentid: this.props.viewer.id,
      connectionName: 'allPosts',
      edgename: 'postEdge',
      rangeBehaviors: {
        '': 'prepend',
      },
    }];
  }
  getVariables() {
    return {
      id: this.props.id,
      title: this.props.title,
      body: this.props.body,
    };
  }
}
