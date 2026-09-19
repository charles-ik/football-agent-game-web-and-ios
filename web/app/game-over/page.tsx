// Game over — full-screen, red-bordered, reading as the end of a story rather
// than an error dialog. The engine warns, then downsizes, then ends the run;
// by the time anyone sees this, they know why.

import Link from "next/link";
import { redirect } from "next/navigation";

import { Money } from "@/components/money";
import { buttonClass } from "@/components/ui";
import { getGameState, isApiError } from "@/lib/api";

export default async function GameOverPage() {
  let state;
  try {
    state = await getGameState();
  } catch (error) {
    if (isApiError(error, "session_not_found")) redirect("/new-game");
    throw error;
  }
  if (!state.game_over) redirect("/");

  return (
    <main className="flex min-h-dvh items-center justify-center px-[max(1rem,env(safe-area-inset-left))] py-[max(2rem,env(safe-area-inset-top))] pr-[max(1rem,env(safe-area-inset-right))] pb-[max(2rem,env(safe-area-inset-bottom))]">
      <div className="anim-rise w-full max-w-lg rounded-xl border border-bad/50 bg-panel p-8 text-center shadow-2xl shadow-bad/10">
        <p className="mb-2 text-xs font-semibold uppercase tracking-[0.3em] text-bad">
          Game over
        </p>
        <h1 className="mb-4 text-xl font-bold">{state.game_over_reason}</h1>
        <dl className="mx-auto mb-6 grid max-w-xs grid-cols-2 gap-y-2 text-sm">
          <dt className="text-left text-dim">Agency</dt>
          <dd className="text-right">{state.agency.name}</dd>
          <dt className="text-left text-dim">Season reached</dt>
          <dd className="num text-right">{state.calendar.season}</dd>
          <dt className="text-left text-dim">Final reputation</dt>
          <dd className="num text-right">
            {state.agency.reputation}{" "}
            <span className="text-faint">({state.agency.reputation_label})</span>
          </dd>
          <dt className="text-left text-dim">Lifetime commission</dt>
          <dd className="num text-right">
            <Money value={state.agency.total_commission} />
          </dd>
        </dl>
        <Link
          href="/new-game"
          className={buttonClass.primary}
        >
          Start again
        </Link>
      </div>
    </main>
  );
}
