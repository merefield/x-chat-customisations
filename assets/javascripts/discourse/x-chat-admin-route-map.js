export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("x-chat-customisations-default-channel", {
      path: "default-channel",
    });
  },
};
