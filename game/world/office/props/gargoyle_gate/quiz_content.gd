class_name QuizContent
## Content of the gargoyle quiz (gargoyle_gate.gd). The question and narrator lines are the team's
## script (docs/narration.md, "Lights out #2"); the gargoyles' balloon lines are PLACEHOLDER (TODO script).
## One question, infinite tries. Answers show in this order (the narrator's `quiz_question` cue reads
## them out in the same order, so keep the two in sync); `correct` = index of the right one.
## Lines: [speaker, text]; speaker "GAR", "GOYLE" or "BOTH". Optional third item: a gesture (animation
## without the "CharacterArmature|" prefix) the speaker plays as the line starts; a fourth: the other
## gargoyle's reaction.

const QUESTION := {
	q = "Can a Match Box?",
	a = ["Yes", "No", "No, but a Tin Can", "What?"],
	correct = 2,
}

const LINES := {
	# First time the player walks up (the statues are still "asleep").
	psst = [["GAR", "Psst. Goyle. Customer."]],
	# X on a statue: the argument that turns into the quiz. The last line slams the lights.
	intro = [
		["GAR", "Halt! None shall pass... without answering three riddles."],
		["GOYLE", "Three? We agreed on two. Two is classier."],
		["GAR", "Two is a PAIR, Goyle. Riddles come in threes. It's in the guild handbook."],
		["GOYLE", "The guild handbook is a napkin, Gar."],
		["GAR", "A LAMINATED napkin. Ahem. Riddle one: what has keys but can't open locks?", "Headbutt", "HitReact"],
		["GOYLE", "A piano. Everybody knows it's a piano. Management says riddles are \"low engagement\"."],
		["GAR", "...Fine. We've been rebranded. ONE question."],
		["BOTH", "LIGHTS!"],
	],
	# Coming back after walking away: straight to the show.
	resume = "Welcome BACK!",
	final_answer = ["Is that your final answer?", "Final answer? Think. Or don't.", "Lock it in, fleshling?"],
	wrong = ["Ooh. Rock bottom. We'd know.", "Wrong, sweetie. Again.", "I've seen gravel with more sense.", "We have all night. We literally cannot leave."],
	clock_zero = "The clock is decorative.",
	walk_away = "Leaving? You'd forfeit your... nothing.",
	walk_away_hint = "(Esc again to walk away)",
	passed = [
		["GAR", "That's... technically right. The worst kind of right."],
		["GOYLE", "Fine. Go. Flip your little switch."],
		["BOTH", "Tip your gargoyles!"],
	],
}
