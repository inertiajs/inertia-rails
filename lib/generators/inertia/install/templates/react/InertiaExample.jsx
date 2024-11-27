import { Head } from '@inertiajs/react'
import { useState } from 'react'

import inertiaSvg from '/assets/inertia.svg'
import reactSvg from '/assets/react.svg'
import viteRubySvg from '/assets/vite_ruby.svg'

import cs from './InertiaExample.module.css'

export default function InertiaExample({ name }) {
  const [count, setCount] = useState(0)

  return (
    <>
      <Head title="Inertia + Vite Ruby + React Example" />

      <div className={cs.root}>
        <h1 className={cs.h1}>Hello {name}!</h1>

        <div>
          <a href="https://inertia-rails.netlify.app" target="_blank">
            <img className={cs.logo} src={inertiaSvg} alt="Inertia logo" />
          </a>
          <a href="https://vite-ruby.netlify.app" target="_blank">
            <img
              className={`${cs.logo} ${cs.vite}`}
              src={viteRubySvg}
              alt="Vite Ruby logo"
            />
          </a>
          <a href="https://react.dev" target="_blank">
            <img
              className={`${cs.logo} ${cs.react}`}
              src={reactSvg}
              alt="React logo"
            />
          </a>
        </div>

        <h2 className={cs.h2}>Inertia + Vite Ruby + React</h2>

        <div className="card">
          <button
            className={cs.button}
            onClick={() => setCount((count) => count + 1)}
          >
            count is {count}
          </button>
          <p>
            Edit <code>app/frontend/pages/InertiaExample.jsx</code> and save to
            test HMR
          </p>
        </div>
        <p className={cs.readTheDocs}>
          Click on the Inertia, Vite Ruby, and React logos to learn more
        </p>
      </div>
    </>
  )
}
