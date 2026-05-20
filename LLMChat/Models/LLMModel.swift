import Foundation

// MARK: - Model Info (mirrors gateway /v1/models response)

struct LLMModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let provider: String
    let free: Bool
    let contextLength: Int
    let description: String
    let supportsVision: Bool
    let supportsTools: Bool
    let tags: [String]
    let pricingNote: String
    var available: Bool
    var missingKey: String?

    enum CodingKeys: String, CodingKey {
        case id, name, provider, free, description, tags, available
        case contextLength  = "context_length"
        case supportsVision = "supports_vision"
        case supportsTools  = "supports_tools"
        case pricingNote    = "pricing_note"
        case missingKey     = "missing_key"
    }

    var providerDisplay: String {
        switch provider {
        case "groq":        return "Groq"
        case "cerebras":    return "Cerebras"
        case "gemini":      return "Google Gemini"
        case "openrouter":  return "OpenRouter"
        case "cloudflare":  return "Cloudflare"
        case "huggingface": return "HuggingFace"
        case "mistral":     return "Mistral"
        case "openai":      return "OpenAI"
        case "anthropic":   return "Anthropic"
        case "xai":         return "xAI (Grok)"
        case "deepseek":    return "DeepSeek"
        case "cohere":      return "Cohere"
        case "together":    return "Together AI"
        case "perplexity":  return "Perplexity"
        case "ollama":      return "Ollama (Local)"
        default:            return provider.capitalized
        }
    }

    var providerColor: String {
        switch provider {
        case "groq":        return "#F55036"
        case "cerebras":    return "#5B21B6"
        case "gemini":      return "#4285F4"
        case "openrouter":  return "#6366F1"
        case "cloudflare":  return "#F38020"
        case "huggingface": return "#FFD21E"
        case "mistral":     return "#FF7000"
        case "openai":      return "#10A37F"
        case "anthropic":   return "#CC785C"
        case "xai":         return "#000000"
        case "deepseek":    return "#4D6BFE"
        case "cohere":      return "#39594D"
        case "together":    return "#0EA5E9"
        case "perplexity":  return "#20808D"
        case "ollama":      return "#333333"
        default:            return "#666666"
        }
    }

    var contextDisplay: String {
        let k = contextLength / 1000
        if k >= 1000 {
            return "\(k / 1000)M ctx"
        }
        return "\(k)K ctx"
    }

    var isReasoning: Bool { tags.contains("reasoning") }
    var isCoding: Bool    { tags.contains("coding") }
    var isFast: Bool      { tags.contains("fast") }
    var isVision: Bool    { supportsVision }
}

// MARK: - Models response wrapper

struct ModelsResponse: Codable {
    let data: [LLMModel]
}

// MARK: - Hardcoded fallback catalog
// Used when the gateway is unreachable so the app still shows models.

extension LLMModel {
    static let fallbackCatalog: [LLMModel] = [
        // --- FREE ---
        LLMModel(id: "groq/llama-3.3-70b-versatile",     name: "Llama 3.3 70B",           provider: "groq",        free: true,  contextLength: 128_000, description: "Meta's best open model. Fast on Groq.",        supportsVision: false, supportsTools: true,  tags: ["fast","large","general"],        pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "groq/llama-3.1-8b-instant",        name: "Llama 3.1 8B (Instant)",   provider: "groq",        free: true,  contextLength: 128_000, description: "Extremely fast small model.",                   supportsVision: false, supportsTools: true,  tags: ["fast","small"],                  pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "groq/deepseek-r1-llama-70b",       name: "DeepSeek R1 Distill 70B",  provider: "groq",        free: true,  contextLength: 128_000, description: "DeepSeek R1 reasoning on Groq.",                supportsVision: false, supportsTools: false, tags: ["reasoning","fast"],               pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "groq/qwen-qwq-32b",                name: "Qwen QwQ 32B",             provider: "groq",        free: true,  contextLength: 128_000, description: "Qwen reasoning model.",                         supportsVision: false, supportsTools: false, tags: ["reasoning","fast"],               pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "groq/llama-3.2-11b-vision",        name: "Llama 3.2 11B Vision",     provider: "groq",        free: true,  contextLength: 128_000, description: "Vision capable Llama.",                         supportsVision: true,  supportsTools: false, tags: ["vision","fast"],                  pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "cerebras/llama-3.3-70b",           name: "Llama 3.3 70B",            provider: "cerebras",    free: true,  contextLength: 128_000, description: "Llama 3.3 on Cerebras silicon. Very fast.",     supportsVision: false, supportsTools: true,  tags: ["fast","large","general"],        pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "cerebras/llama-3.1-8b",            name: "Llama 3.1 8B",             provider: "cerebras",    free: true,  contextLength: 128_000, description: "Fastest small model available.",                supportsVision: false, supportsTools: true,  tags: ["fast","small"],                  pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "gemini/gemini-2.0-flash",          name: "Gemini 2.0 Flash",         provider: "gemini",      free: true,  contextLength: 1_048_576, description: "Google's best free model. 1M context.",       supportsVision: true,  supportsTools: true,  tags: ["fast","large-context","vision"], pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "gemini/gemini-2.0-flash-thinking", name: "Gemini 2.0 Flash Thinking",provider: "gemini",      free: true,  contextLength: 32_767,  description: "Thinking/reasoning variant.",                   supportsVision: false, supportsTools: false, tags: ["reasoning"],                     pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "gemini/gemini-1.5-flash",          name: "Gemini 1.5 Flash",         provider: "gemini",      free: true,  contextLength: 1_048_576, description: "1M context free.",                            supportsVision: true,  supportsTools: true,  tags: ["fast","large-context","vision"], pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "openrouter/deepseek-r1-free",      name: "DeepSeek R1",              provider: "openrouter",  free: true,  contextLength: 163_840, description: "Full DeepSeek R1 reasoning.",                   supportsVision: false, supportsTools: false, tags: ["reasoning","large"],              pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "openrouter/deepseek-v3-free",      name: "DeepSeek V3",              provider: "openrouter",  free: true,  contextLength: 163_840, description: "DeepSeek V3 via OpenRouter.",                   supportsVision: false, supportsTools: false, tags: ["large","general"],                pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "openrouter/llama-3.3-70b-free",    name: "Llama 3.3 70B",            provider: "openrouter",  free: true,  contextLength: 128_000, description: "Via OpenRouter free tier.",                     supportsVision: false, supportsTools: true,  tags: ["large","general"],                pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "openrouter/qwq-32b-free",          name: "Qwen QwQ 32B",             provider: "openrouter",  free: true,  contextLength: 131_072, description: "Reasoning model via OpenRouter.",               supportsVision: false, supportsTools: false, tags: ["reasoning"],                     pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "cloudflare/llama-3.3-70b",         name: "Llama 3.3 70B FP8",        provider: "cloudflare",  free: true,  contextLength: 128_000, description: "Fast FP8 quantized on Cloudflare.",             supportsVision: false, supportsTools: false, tags: ["fast","large"],                   pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "cloudflare/llama-3.1-8b",          name: "Llama 3.1 8B",             provider: "cloudflare",  free: true,  contextLength: 128_000, description: "Small model on Cloudflare.",                    supportsVision: false, supportsTools: false, tags: ["small","fast"],                   pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "mistral/open-mistral-nemo",        name: "Mistral Nemo (Free)",       provider: "mistral",     free: true,  contextLength: 128_000, description: "12B model, free tier.",                         supportsVision: false, supportsTools: false, tags: ["small","fast"],                   pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "hf/mistral-7b",                    name: "Mistral 7B v0.3",           provider: "huggingface", free: true,  contextLength: 32_768,  description: "Free, no rate limit. Slow.",                    supportsVision: false, supportsTools: false, tags: ["small","slow"],                   pricingNote: "", available: true, missingKey: nil),
        // Ollama local
        LLMModel(id: "ollama/llama3.3",                  name: "Llama 3.3 (Local)",         provider: "ollama",      free: true,  contextLength: 128_000, description: "Run locally via Ollama.",                       supportsVision: false, supportsTools: false, tags: ["local","large"],                  pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "ollama/deepseek-r1",               name: "DeepSeek R1 (Local)",       provider: "ollama",      free: true,  contextLength: 128_000, description: "DeepSeek R1 running locally.",                  supportsVision: false, supportsTools: false, tags: ["local","reasoning"],              pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "ollama/devstral",                  name: "Devstral (Local)",           provider: "ollama",      free: true,  contextLength: 32_768,  description: "Mistral agentic coding model, local.",          supportsVision: false, supportsTools: false, tags: ["local","coding"],                 pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "ollama/phi4",                      name: "Phi-4 (Local)",              provider: "ollama",      free: true,  contextLength: 16_384,  description: "Microsoft Phi-4, local.",                       supportsVision: false, supportsTools: false, tags: ["local","small"],                  pricingNote: "", available: true, missingKey: nil),
        LLMModel(id: "ollama/qwen2.5-coder",             name: "Qwen 2.5 Coder (Local)",    provider: "ollama",      free: true,  contextLength: 128_000, description: "Best local coding model.",                      supportsVision: false, supportsTools: false, tags: ["local","coding"],                 pricingNote: "", available: true, missingKey: nil),
        // --- PAID ---
        LLMModel(id: "openai/gpt-4o",                    name: "GPT-4o",                    provider: "openai",      free: false, contextLength: 128_000, description: "OpenAI's flagship multimodal.",                 supportsVision: true,  supportsTools: true,  tags: ["flagship","vision"],              pricingNote: "$2.50/1M in", available: false, missingKey: "OPENAI_API_KEY"),
        LLMModel(id: "openai/gpt-4o-mini",               name: "GPT-4o Mini",               provider: "openai",      free: false, contextLength: 128_000, description: "Fast and cheap OpenAI model.",                  supportsVision: false, supportsTools: true,  tags: ["small","fast"],                   pricingNote: "$0.15/1M in", available: false, missingKey: "OPENAI_API_KEY"),
        LLMModel(id: "openai/o3",                        name: "o3",                        provider: "openai",      free: false, contextLength: 200_000, description: "Best reasoning model.",                         supportsVision: false, supportsTools: false, tags: ["reasoning","flagship"],           pricingNote: "$10/1M in",   available: false, missingKey: "OPENAI_API_KEY"),
        LLMModel(id: "openai/o3-mini",                   name: "o3 Mini",                   provider: "openai",      free: false, contextLength: 200_000, description: "Compact o3 reasoning.",                         supportsVision: false, supportsTools: false, tags: ["reasoning","fast"],               pricingNote: "$1.10/1M in", available: false, missingKey: "OPENAI_API_KEY"),
        LLMModel(id: "openai/o4-mini",                   name: "o4 Mini",                   provider: "openai",      free: false, contextLength: 200_000, description: "Latest mini reasoning.",                        supportsVision: false, supportsTools: false, tags: ["reasoning","fast"],               pricingNote: "$1.10/1M in", available: false, missingKey: "OPENAI_API_KEY"),
        LLMModel(id: "openai/o1",                        name: "o1",                        provider: "openai",      free: false, contextLength: 200_000, description: "Strong reasoning.",                             supportsVision: false, supportsTools: false, tags: ["reasoning"],                     pricingNote: "$15/1M in",   available: false, missingKey: "OPENAI_API_KEY"),
        LLMModel(id: "anthropic/claude-opus-4",          name: "Claude Opus 4",             provider: "anthropic",   free: false, contextLength: 200_000, description: "Most intelligent Claude.",                      supportsVision: true,  supportsTools: true,  tags: ["flagship","reasoning"],           pricingNote: "$15/1M in",   available: false, missingKey: "ANTHROPIC_API_KEY"),
        LLMModel(id: "anthropic/claude-sonnet-4",        name: "Claude Sonnet 4",           provider: "anthropic",   free: false, contextLength: 200_000, description: "Best balance in the Claude family.",            supportsVision: true,  supportsTools: true,  tags: ["flagship","fast"],                pricingNote: "$3/1M in",    available: false, missingKey: "ANTHROPIC_API_KEY"),
        LLMModel(id: "anthropic/claude-3.5-haiku",       name: "Claude 3.5 Haiku",          provider: "anthropic",   free: false, contextLength: 200_000, description: "Fastest Claude.",                               supportsVision: false, supportsTools: true,  tags: ["small","fast"],                   pricingNote: "$0.80/1M in", available: false, missingKey: "ANTHROPIC_API_KEY"),
        LLMModel(id: "gemini/gemini-2.5-pro",            name: "Gemini 2.5 Pro",            provider: "gemini",      free: false, contextLength: 1_048_576, description: "Google's best paid model.",                   supportsVision: true,  supportsTools: true,  tags: ["flagship","reasoning","vision"],  pricingNote: "$1.25/1M in", available: false, missingKey: "GEMINI_API_KEY"),
        LLMModel(id: "mistral/codestral",                name: "Codestral",                 provider: "mistral",     free: false, contextLength: 32_768,  description: "Best code model from Mistral.",                 supportsVision: false, supportsTools: true,  tags: ["coding"],                        pricingNote: "$0.20/1M in", available: false, missingKey: "MISTRAL_API_KEY"),
        LLMModel(id: "mistral/devstral",                 name: "Devstral",                  provider: "mistral",     free: false, contextLength: 32_768,  description: "Agentic coding model.",                         supportsVision: false, supportsTools: true,  tags: ["coding","agents"],                pricingNote: "$0.10/1M in", available: false, missingKey: "MISTRAL_API_KEY"),
        LLMModel(id: "mistral/mistral-large",            name: "Mistral Large",             provider: "mistral",     free: false, contextLength: 128_000, description: "Flagship Mistral model.",                       supportsVision: false, supportsTools: true,  tags: ["large","general"],                pricingNote: "$2/1M in",    available: false, missingKey: "MISTRAL_API_KEY"),
        LLMModel(id: "xai/grok-3",                       name: "Grok 3",                    provider: "xai",         free: false, contextLength: 131_072, description: "xAI's flagship model.",                         supportsVision: false, supportsTools: true,  tags: ["flagship","general"],             pricingNote: "$3/1M in",    available: false, missingKey: "XAI_API_KEY"),
        LLMModel(id: "xai/grok-3-mini",                  name: "Grok 3 Mini",               provider: "xai",         free: false, contextLength: 131_072, description: "Fast Grok 3 variant.",                          supportsVision: false, supportsTools: true,  tags: ["small","fast","reasoning"],       pricingNote: "$0.30/1M in", available: false, missingKey: "XAI_API_KEY"),
        LLMModel(id: "deepseek/deepseek-v3",             name: "DeepSeek V3",               provider: "deepseek",    free: false, contextLength: 128_000, description: "Very cheap. Stronger than most.",               supportsVision: false, supportsTools: true,  tags: ["large","coding"],                 pricingNote: "$0.07/1M in", available: false, missingKey: "DEEPSEEK_API_KEY"),
        LLMModel(id: "deepseek/deepseek-r1",             name: "DeepSeek R1",               provider: "deepseek",    free: false, contextLength: 128_000, description: "Full R1 reasoning chain.",                      supportsVision: false, supportsTools: false, tags: ["reasoning","large"],              pricingNote: "$0.55/1M in", available: false, missingKey: "DEEPSEEK_API_KEY"),
        LLMModel(id: "perplexity/sonar-pro",             name: "Sonar Pro",                 provider: "perplexity",  free: false, contextLength: 127_072, description: "Web-connected search model.",                   supportsVision: false, supportsTools: false, tags: ["search","large"],                 pricingNote: "$3/1M in",    available: false, missingKey: "PERPLEXITY_API_KEY"),
        LLMModel(id: "cohere/command-r-plus",            name: "Command R+",                provider: "cohere",      free: false, contextLength: 128_000, description: "Best RAG/search model from Cohere.",            supportsVision: false, supportsTools: true,  tags: ["large","rag"],                    pricingNote: "$2.50/1M in", available: false, missingKey: "COHERE_API_KEY"),
        LLMModel(id: "together/llama-3.1-405b",          name: "Llama 3.1 405B",            provider: "together",    free: false, contextLength: 130_815, description: "Largest Llama, via Together.",                  supportsVision: false, supportsTools: true,  tags: ["large","general"],                pricingNote: "$3.50/1M in", available: false, missingKey: "TOGETHER_API_KEY"),
    ]
}
