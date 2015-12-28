import Relay from 'react-relay'

export default class EditPostMutation extends Relay.Mutation {
  static fragments = {
    post: () => Relay.QL`
      fragment on Post {
        id
        title
        body
      }
    `,
  };
  getMutation() {
    return Relay.QL`mutation{editPost}`;
  }
  getFatQuery() {
    return Relay.QL`
      fragment on EditPostPayload {
        post {
          title
          body
          updated_at
        }
      }
    `;
  }
  getConfigs() {
    return [{
      type: 'FIELDS_CHANGE',
      fieldIDs: {
        post: this.props.id,
      }
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

