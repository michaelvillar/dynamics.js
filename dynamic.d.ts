namespace dynamics {
type Type =
  | typeof spring
  | typeof linear
  | typeof gravity
  | typeof easeIn
  | typeof easeInOut
  | typeof easeOut
  | typeof bounce
  | typeof bezier
  | typeof forceWithGravity;

interface Options<P, T> {
  duration?: number;
  type?: T;
  complete?(): void;
  change?(target: P, progress: number): void;
}

function animate<P, T extends Type = typeof easeInOut>(
  target: P,
  properties: P,
  options?: Options<P, T> & Parameters<T>[0]
): number;

function spring(config?: {
  frequency?: number;
  friction?: number;
  anticipationSize?: number;
  anticipationStrength?: number;
}): void;

function bounce(config?: { frequency?: number; friction?: number }): void;

function forceWithGravity(config?: {
  bounciness?: number;
  elasticity?: number;
}): void;

function gravity(config?: {
  bounciness?: number;
  elasticity?: number;
}): void;

function easeOut(config?: { friction?: number }): void;

function easeIn(config?: { friction?: number }): void;

function easeInOut(config?: { friction?: number }): void;

function linear(): void;

function bezier(config?: { points: any[] }): void;

function setTimeout(fn: (...args: any[]) => void, delay: number): number;

function clearTimeout(id: number): void;

function stop<P>(target: P): void;

function toggleSlow(): void;

function css<T extends HTMLElement>(el: T, properties: T["style"]): number;
}

export default dynamics;
