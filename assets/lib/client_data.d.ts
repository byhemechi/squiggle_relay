import SquiggleRealtime from "squiggle_realtime";

export declare const activeChannels: Set<string>;
declare const SquiggleChannel: {
  readonly [channelName: string]: Promise<SquiggleRealtime>;
};
export default SquiggleChannel;
