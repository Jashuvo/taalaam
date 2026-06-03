{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine({
      // Use the locally-bundled CanvasKit assets instead of the gstatic CDN.
      // flutter build web includes canvaskit/ in the output; pointing here
      // avoids runtime CDN fetches that can time out on restricted networks.
      canvasKitBaseUrl: "canvaskit/"
    });
    await appRunner.runApp();
  }
});
