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
        created_at
        draft
      }
    `,
  };
  getMutation () {
    return Relay.QL`mutation{savePost}`
  }
  getFatQuery () {
    return Relay.QL`
      fragment on SavePostPayload {
        postEdge
        viewer {
          id
          allPosts
          allDrafts
        }
      }
    `
  }
  getConfigs () {
    return [{
      type: 'FIELDS_CHANGE',
      fieldIDs: {
        viewer: this.props.viewer.id,
      },
    }]
  }
  getVariables () {
    return {
      id: this.props.id,
      title: this.props.title,
      body: this.props.body,
      created_at: this.props.created_at,
    }
  }
}
