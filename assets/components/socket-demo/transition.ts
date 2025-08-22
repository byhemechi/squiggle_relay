export default function transition(
  callback: (isPolyfilled: boolean) => void,
): void {
  if (typeof document.startViewTransition !== "undefined") {
    document.startViewTransition(() => callback(false));
  } else callback(true);
}
