const fs = require('fs')
const path = require('path')
const matter = require('gray-matter')

// Configuration
const DOCS_DIR = path.join(__dirname, '..')
const OUTPUT_FILE = path.join(DOCS_DIR, 'public', 'llms-full.txt')
const EXCLUDED_DIRS = ['node_modules', '.vitepress', 'dist', 'cache', 'scripts']
const EXCLUDED_FILES = ['.DS_Store', 'package.json', 'package-lock.json']

// Helper to clean markdown content
function cleanMarkdown(content) {
  return (
    content
      // Format code blocks to be more LLM-friendly
      .replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
        // Remove the language identifier if present and clean up the code
        return `CODE BLOCK${lang ? ` (${lang})` : ''}:\n${code.trim()}\n\n`
      })
      // Remove inline code but preserve the content
      .replace(/`([^`]*)`/g, '$1')
      // Remove HTML comments
      .replace(/<!--[\s\S]*?-->/g, '')
      // Remove frontmatter
      .replace(/---[\s\S]*?---/g, '')
      // Remove tabs syntax
      .replace(/:::tabs[\s\S]*?:::/g, '')
      // Remove images
      .replace(/!\[.*?\]\(.*?\)/g, '')
      // Remove links but keep text
      .replace(/\[([^\]]*)\]\(.*?\)/g, '$1')
      // Remove HTML tags
      .replace(/<[^>]*>/g, '')
      // Remove multiple newlines
      .replace(/\n{3,}/g, '\n\n')
      // Remove leading/trailing whitespace
      .trim()
  )
}

// Helper to walk directory recursively
function* walkDir(dir) {
  const files = fs.readdirSync(dir)

  for (const file of files) {
    const filePath = path.join(dir, file)
    const stat = fs.statSync(filePath)

    if (EXCLUDED_DIRS.includes(file) || EXCLUDED_FILES.includes(file)) {
      continue
    }

    if (stat.isDirectory()) {
      yield* walkDir(filePath)
    } else if (stat.isFile() && file.endsWith('.md')) {
      yield filePath
    }
  }
}

// Main extraction function
function extractDocs() {
  let output = ''

  // Add metadata
  output += '# Inertia Rails Documentation\n'
  output += `Extracted on: ${new Date().toISOString()}\n\n`
  output +=
    'Note: Code blocks are preserved and formatted for LLM consumption.\n\n'

  // Process each markdown file
  for (const filePath of walkDir(DOCS_DIR)) {
    const relativePath = path.relative(DOCS_DIR, filePath)

    // Skip awesome.md as it's just links and not useful for LLMs
    if (relativePath === 'awesome.md') {
      continue
    }

    const content = fs.readFileSync(filePath, 'utf8')
    const { data, content: markdownContent } = matter(content)

    const cleanedContent = cleanMarkdown(markdownContent)

    if (cleanedContent.trim()) {
      output += `## ${relativePath}\n\n`

      // Add frontmatter title if available
      if (data.title) {
        output += `Title: ${data.title}\n\n`
      }

      output += cleanedContent + '\n\n'
      output += '---\n\n'
    }
  }

  // Add auto-generated sections
  output += generateCrossReferenceIndex()
  output += generateAPIReference()

  // Write output file
  fs.writeFileSync(OUTPUT_FILE, output)
  console.log(`Documentation extracted to: ${OUTPUT_FILE}`)
}

// Generate cross-reference index based on content analysis
function generateCrossReferenceIndex(allContent) {
  const sections = []
  const keywords = new Map()

  // Extract sections and their keywords
  for (const filePath of walkDir(DOCS_DIR)) {
    const relativePath = path.relative(DOCS_DIR, filePath)

    // Skip awesome.md as it's just links and not useful for LLMs
    if (relativePath === 'awesome.md') {
      continue
    }

    const content = fs.readFileSync(filePath, 'utf8')
    const { content: markdownContent } = matter(content)

    if (markdownContent.trim()) {
      const cleanContent = cleanMarkdown(markdownContent)
      const sectionTitle = relativePath.replace('.md', '')

      // Extract key terms (method names, component names, etc.)
      const codeBlocks =
        cleanContent.match(
          /CODE BLOCK \([^)]+\):\n([\s\S]*?)(?=\n\n|\n#|$)/g,
        ) || []
      const methodNames = []
      const componentNames = []

      codeBlocks.forEach((block) => {
        // Extract Rails method names
        const railsMethods =
          block.match(/def \w+|render inertia:|inertia_share|router\.\w+/g) ||
          []
        methodNames.push(...railsMethods)

        // Extract component names
        const components =
          block.match(/[A-Z][a-zA-Z]*(?:Component|Page|Layout)/g) || []
        componentNames.push(...components)
      })

      sections.push({
        title: sectionTitle,
        path: relativePath,
        methods: [...new Set(methodNames)],
        components: [...new Set(componentNames)],
        content: cleanContent,
      })
    }
  }

  // Build cross-reference map
  let crossRefIndex = '\n# CROSS-REFERENCE INDEX\n\n'

  // Group by functionality
  const functionalGroups = {
    'Authentication & Authorization': [
      'authentication',
      'authorization',
      'csrf',
      'current_user',
      'authenticate',
    ],
    'Forms & Validation': [
      'forms',
      'validation',
      'useForm',
      'errors',
      'redirect_back',
    ],
    'Routing & Navigation': [
      'routing',
      'links',
      'router.visit',
      'manual-visits',
      'redirects',
    ],
    'Data Management': [
      'responses',
      'props',
      'shared-data',
      'partial-reloads',
      'deferred-props',
    ],
    'File Handling': ['file-uploads', 'FormData', 'multipart'],
    Performance: ['asset-versioning', 'code-splitting', 'prefetching', 'ssr'],
    'Testing & Debugging': ['testing', 'error-handling', 'progress-indicators'],
  }

  Object.entries(functionalGroups).forEach(([category, keywords]) => {
    crossRefIndex += `## ${category}\n\n`

    const relatedSections = sections.filter((section) =>
      keywords.some(
        (keyword) =>
          section.title.toLowerCase().includes(keyword) ||
          section.content.toLowerCase().includes(keyword),
      ),
    )

    relatedSections.forEach((section) => {
      crossRefIndex += `- **${section.title}**: Key methods/components: ${[...section.methods, ...section.components].slice(0, 3).join(', ')}\n`
    })

    crossRefIndex += '\n'
  })

  return crossRefIndex
}

// Generate API reference from code blocks
function generateAPIReference() {
  let apiRef = '\n# API REFERENCE\n\n'

  const codeExamples = {
    'Rails Controller Methods': [],
    'Inertia Client Methods': [],
    'Configuration Options': [],
    'Form Helpers': [],
    'Component Props': [],
  }

  for (const filePath of walkDir(DOCS_DIR)) {
    const relativePath = path.relative(DOCS_DIR, filePath)

    // Skip awesome.md as it's just links and not useful for LLMs
    if (relativePath === 'awesome.md') {
      continue
    }

    const content = fs.readFileSync(filePath, 'utf8')
    const { content: markdownContent } = matter(content)
    const cleanContent = cleanMarkdown(markdownContent)
    const sectionName = relativePath.replace('.md', '')

    // Extract Ruby code blocks
    const rubyBlocks =
      cleanContent.match(/CODE BLOCK \(ruby\):\n([\s\S]*?)(?=\n\n|\n#|$)/g) ||
      []
    rubyBlocks.forEach((block) => {
      const code = block.replace('CODE BLOCK (ruby):\n', '')

      // Extract controller methods
      const controllerMethods = code.match(/def \w+[\s\S]*?end/g) || []
      controllerMethods.forEach((method) => {
        const methodName = method.match(/def (\w+)/)?.[1]
        if (methodName) {
          codeExamples['Rails Controller Methods'].push({
            method: methodName,
            source: sectionName,
            code: method.trim(),
          })
        }
      })

      // Extract configuration
      const configBlocks =
        code.match(/InertiaRails\.configure[\s\S]*?end/g) || []
      configBlocks.forEach((config) => {
        codeExamples['Configuration Options'].push({
          source: sectionName,
          code: config.trim(),
        })
      })
    })

    // Extract JavaScript/TypeScript code blocks
    const jsBlocks =
      cleanContent.match(
        /CODE BLOCK \((js|javascript|typescript|jsx|tsx)\):\n([\s\S]*?)(?=\n\n|\n#|$)/g,
      ) || []
    jsBlocks.forEach((block) => {
      const code = block.replace(/CODE BLOCK \([^)]+\):\n/, '')

      // Extract router methods
      const routerMethods = code.match(/router\.\w+\([^}]*\}/g) || []
      routerMethods.forEach((method) => {
        const methodName = method.match(/router\.(\w+)/)?.[1]
        if (methodName) {
          codeExamples['Inertia Client Methods'].push({
            method: methodName,
            source: sectionName,
            code: method.trim(),
          })
        }
      })

      // Extract useForm usage
      const formUsage = code.match(/useForm\([^}]*\}/g) || []
      formUsage.forEach((usage) => {
        codeExamples['Form Helpers'].push({
          source: sectionName,
          code: usage.trim(),
        })
      })
    })
  }

  // Generate organized API reference
  Object.entries(codeExamples).forEach(([category, examples]) => {
    if (examples.length > 0) {
      apiRef += `## ${category}\n\n`

      // Group by method name for controller and client methods
      if (category.includes('Methods')) {
        const methodGroups = {}
        examples.forEach((example) => {
          if (!methodGroups[example.method]) {
            methodGroups[example.method] = []
          }
          methodGroups[example.method].push(example)
        })

        Object.entries(methodGroups).forEach(([methodName, methodExamples]) => {
          apiRef += `### ${methodName}\n\n`
          apiRef += `Used in: ${methodExamples.map((e) => e.source).join(', ')}\n\n`
          apiRef += `\`\`\`ruby\n${methodExamples[0].code}\n\`\`\`\n\n`
        })
      } else {
        // For other categories, just list examples
        examples.forEach((example, index) => {
          apiRef += `### Example ${index + 1} (from ${example.source})\n\n`
          apiRef += `\`\`\`ruby\n${example.code}\n\`\`\`\n\n`
        })
      }
    }
  })

  return apiRef
}

// Run extraction
extractDocs()
