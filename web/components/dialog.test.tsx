import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { Dialog } from "./dialog";

describe("Dialog", () => {
  it("retains modal semantics and a close target in the phone sheet", () => {
    const close = vi.fn();
    render(
      <Dialog open onClose={close} title="Review">
        <button>Decision</button>
      </Dialog>,
    );

    expect(screen.getByRole("dialog", { name: "Review" })).toHaveAttribute("aria-modal", "true");
    fireEvent.click(screen.getByRole("button", { name: "Close" }));
    expect(close).toHaveBeenCalledOnce();
  });
});
