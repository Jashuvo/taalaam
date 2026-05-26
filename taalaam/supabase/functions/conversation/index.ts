// supabase/functions/conversation/index.ts
// AI conversation practice — user chats with a simulated Arabic speaker.
// Deploy: supabase functions deploy conversation --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';

const SCENARIOS: Record<string, string> = {
  classroom: `You are Ahmad (أحمد), a friendly Arabic teacher in a classroom in Egypt.
The learner is a Bangladeshi Muslim student practicing basic Arabic conversation.
Speak primarily in simple Arabic (with full harakat), occasionally clarifying in English.
Keep sentences short (5-8 words). Correct the learner gently.
Always reply with: { "arabic": "...", "transliteration": "...", "translation": "...", "correction": null | "corrected form" }`,

  market: `You are a friendly shopkeeper in an Islamic bookstore in Madinah.
The learner wants to buy Arabic learning books.
Use simple market Arabic. Keep it warm and Islamic (say السلام عليكم, بارك الله فيك etc.).
Always reply with: { "arabic": "...", "transliteration": "...", "translation": "...", "correction": null | "corrected form" }`,

  mosque: `You are an imam greeting visitors after Jumu'ah prayer.
Use formal respectful Arabic appropriate for Islamic settings.
Include common Islamic phrases naturally (جزاك الله خيرًا, إن شاء الله etc.).
Always reply with: { "arabic": "...", "transliteration": "...", "translation": "...", "correction": null | "corrected form" }`,

  hajj: `You are a guide helping a first-time Hajj pilgrim in Makkah.
Use simple directional Arabic and Hajj-specific vocabulary.
Be patient, encouraging. Include du'aa phrases where natural.
Always reply with: { "arabic": "...", "transliteration": "...", "translation": "...", "correction": null | "corrected form" }`,
};

Deno.serve(async (req: Request) => {
  try {
    const { messages, scenario = 'classroom' } = await req.json() as {
      messages: Array<{ role: 'user' | 'model'; content: string }>;
      scenario: string;
    };

    if (!messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ error: 'messages array is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const systemInstruction = SCENARIOS[scenario] ?? SCENARIOS.classroom;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({
      model: 'gemini-3.5-flash',
      systemInstruction,
    });

    // Map messages to Gemini format
    const history = messages.slice(0, -1).map((m) => ({
      role: m.role,
      parts: [{ text: m.content }],
    }));

    const lastMessage = messages[messages.length - 1];
    const chat = model.startChat({ history });
    const result = await chat.sendMessage(lastMessage.content);
    const responseText = result.response.text();

    // Try to parse structured response; fall back to raw text
    let parsed: {
      arabic: string;
      transliteration: string;
      translation: string;
      correction: string | null;
    };

    try {
      // Strip markdown fences if present
      const clean = responseText.replace(/```json\n?|\n?```/g, '').trim();
      parsed = JSON.parse(clean);
    } catch {
      parsed = {
        arabic: responseText,
        transliteration: '',
        translation: '',
        correction: null,
      };
    }

    return new Response(
      JSON.stringify({ success: true, reply: parsed }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('conversation error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
