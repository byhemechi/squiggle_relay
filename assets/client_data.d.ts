declare module "client_data" {
  import SquiggleRealtime from "squiggle_realtime";

  export const activeChannels: Set<string>;
  const SquiggleChannel: {
    readonly [channelName: string]: Promise<SquiggleRealtime>;
  };
  export default SquiggleChannel;
}
