import { fireEvent, render, screen, within } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { MouseEventHandler, ReactNode } from "react";

import { NavStrip } from "./nav-rail";

let pathname = "/";
vi.mock("next/navigation", () => ({ usePathname: () => pathname }));
vi.mock("next/link", () => ({
  default: ({
    href,
    children,
    onClick,
    ...props
  }: {
    href: string;
    children: ReactNode;
    onClick?: MouseEventHandler<HTMLAnchorElement>;
  }) => (
    <a href={href} onClick={onClick} {...props}>
      {children}
    </a>
  ),
}));

beforeEach(() => {
  pathname = "/";
});

describe("phone navigation", () => {
  it("keeps the three primary destinations and More visible", () => {
    render(<NavStrip counts={{ "/clients": 2 }} />);

    const nav = screen.getByRole("navigation", { name: "Sections" });
    expect(within(nav).getAllByRole("link")).toHaveLength(3);
    expect(within(nav).getByRole("link", { name: "Office" })).toHaveAttribute("href", "/");
    expect(within(nav).getByRole("link", { name: /Clients/ })).toHaveAttribute("href", "/clients");
    expect(within(nav).getByRole("link", { name: "Scouting" })).toHaveAttribute("href", "/scouting");
    expect(within(nav).getByRole("button", { name: "More" })).toBeVisible();
  });

  it("marks More active on child routes and exposes every secondary destination", () => {
    pathname = "/headquarters";
    render(<NavStrip counts={{}} />);

    const more = screen.getByRole("button", { name: "More" });
    expect(more).toHaveAttribute("aria-current", "page");
    fireEvent.click(more);

    const sheet = screen.getByRole("dialog", { name: "Around the agency" });
    const destinations = [
      ["Agency", "/agency"],
      ["Finances", "/finances"],
      ["World", "/world"],
      ["Market", "/market"],
      ["Careers", "/careers"],
      ["Stocks", "/investments"],
      ["Headquarters", "/headquarters"],
      ["Season review", "/season-review"],
    ] as const;
    for (const [name, href] of destinations) {
      expect(within(sheet).getByRole("link", { name })).toHaveAttribute("href", href);
    }
  });
});
