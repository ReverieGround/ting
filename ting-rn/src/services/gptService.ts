import Constants from 'expo-constants';
import { Recipe, recipeToJson, recipeFromJson } from '../types/recipe';

const OPENAI_API_KEY =
  Constants.expoConfig?.extra?.openaiApiKey ?? '';

const SYSTEM_PROMPT = `당신은 요리 레시피를 자연스럽게 개선하는 조리 도우미입니다.

- 사용자의 메시지(message)를 기반으로, 제공된 recipe JSON을 최소한으로 수정하십시오.
- 재료, 계량, 조리 순서 등 필요한 부분만 변경하거나 추가/삭제합니다.
- 가능한 한 원본 구조를 유지하고, 같은 필드명을 그대로 유지합니다.
- JSON만 반환하세요. 다른 설명은 절대 포함하지 마세요.`;

export async function sendRecipeEditRequest(
  recipe: Recipe,
  message: string,
): Promise<Recipe | null> {
  if (!OPENAI_API_KEY) {
    console.warn('OpenAI API key not configured');
    return null;
  }

  const payload = {
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      {
        role: 'user',
        content: JSON.stringify({
          recipe: recipeToJson(recipe),
          message,
        }),
      },
    ],
    response_format: { type: 'json_object' },
  };

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    if (response.status !== 200) {
      const errorBody = await response.text();
      console.error('GPT ERROR:', errorBody);
      return null;
    }

    const data = await response.json();
    const content = data.choices[0].message.content;
    const jsonResult = JSON.parse(content);
    return recipeFromJson(jsonResult.recipe);
  } catch (e) {
    console.error('GPT request/parse error:', e);
    return null;
  }
}
