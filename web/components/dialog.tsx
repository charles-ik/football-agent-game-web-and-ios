"use client";

// A minimal modal dialog — the only primitives the plan asks for, hand-rolled
// in the shadcn style rather than adopting a component library wholesale.
// Esc closes; a click on the backdrop closes. Focus is trapped inside while
// open and restored to whatever opened it on close — the accessibility floor
// for a modal flow that otherwise strands keyboard and screen-reader users.

import { useEffect, useRef, type ReactNode } from "react";
import { buttonClass } from "@/components/ui";

const FOCUSABLE =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

export function Dialog({
  open,
  onClose,
  title,
  children,
  wide = false,
  side = false,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  wide?: boolean;
  side?: boolean;
}) {
  const panelRef = useRef<HTMLDivElement>(null);
  const openerRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.stopPropagation();
        onClose();
        return;
      }
      if (event.key !== "Tab" || !panelRef.current) return;
      const focusable = Array.from(panelRef.current.querySelectorAll<HTMLElement>(FOCUSABLE));
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    window.addEventListener("keydown", onKey, true);
    return () => window.removeEventListener("keydown", onKey, true);
  }, [open, onClose]);

  useEffect(() => {
    if (!open) return;
    openerRef.current = document.activeElement as HTMLElement | null;
    const focusable = panelRef.current?.querySelector<HTMLElement>(FOCUSABLE);
    (focusable ?? panelRef.current)?.focus();
    return () => {
      openerRef.current?.focus?.();
    };
  }, [open]);

  if (!open) return null;
  return (
    <div
      className={`fixed inset-0 z-40 flex items-end bg-black/70 px-0 pt-[max(1rem,env(safe-area-inset-top))] backdrop-blur-sm sm:items-center sm:p-4 ${side ? "justify-end" : "justify-center"}`}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
      role="presentation"
    >
      <div
        ref={panelRef}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        className={`anim-rise max-h-[calc(100dvh-env(safe-area-inset-top)-1rem)] w-full overscroll-contain overflow-y-auto rounded-t-2xl border border-line bg-panel pb-[env(safe-area-inset-bottom)] shadow-2xl shadow-black/70 outline-none sm:max-h-[85vh] sm:rounded-xl sm:pb-0 ${
          side
            ? "sm:h-dvh sm:max-h-dvh sm:max-w-2xl sm:rounded-none"
            : wide
              ? "sm:max-w-2xl"
              : "sm:max-w-md"
        }`}
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-line bg-panel/95 px-4 py-3 backdrop-blur">
          <h2 className="t-section">{title}</h2>
          <button
            onClick={onClose}
            aria-label="Close"
            className={buttonClass.ghost}
          >
            ✕
          </button>
        </div>
        <div className="px-4 py-4">{children}</div>
      </div>
    </div>
  );
}
