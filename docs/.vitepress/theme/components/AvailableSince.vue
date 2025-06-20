<script setup lang="ts">
import {computed} from 'vue';

const props = defineProps<{
  rails?: string;
  core?: string;
  description?: string;
}>();

const railsVersion = computed(() => {
  if (!props.rails) return null;
  return {version: props.rails};
});

const coreVersion = computed(() => {
  if (!props.core) return null;
  return {version: props.core};
});

</script>

<template>
  <div class="available-since">
    <span class="label">Available since:</span>

    <template v-if="railsVersion">
      <span class="version-badge" title="inertia_rails" aria-label="inertia_rails version {{ railsVersion.version }}">
        <!-- Ruby Logo SVG -->
        <svg class="logo-svg ruby-logo" width="16" height="16" viewBox="0 0 30 30"><defs><linearGradient id="b"
                                                                                                         x1="-235.957"
                                                                                                         x2="-235.986"
                                                                                                         y1="-308.579"
                                                                                                         y2="-308.527"
                                                                                                         gradientTransform="matrix(202.935 0 0 -202.78 47910.461 -62541.16)"
                                                                                                         gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#fb7655"/><stop offset=".41" stop-color="#e42b1e"/><stop offset=".99"
                                                                                            stop-color="#900"/><stop
            offset="1" stop-color="#900"/></linearGradient><linearGradient id="a" x1="-235.571" x2="-235.697"
                                                                           y1="-309.087" y2="-309.041"
                                                                           gradientTransform="matrix(60.308 0 0 -111.778 14236.351 -34525.395)"
                                                                           gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#871101"/><stop offset=".99" stop-color="#911209"/><stop offset="1"
                                                                                            stop-color="#911209"/></linearGradient><linearGradient
            id="c" x1="-235.896" x2="-235.937" y1="-313.362" y2="-313.129"
            gradientTransform="matrix(188.32 0 0 -21.986 44447.302 -6856.882)" href="#a"/><linearGradient id="d"
                                                                                                          x1="-233.515"
                                                                                                          x2="-233.497"
                                                                                                          y1="-309.082"
                                                                                                          y2="-309.161"
                                                                                                          gradientTransform="matrix(65.222 0 0 -97.1 15237.802 -29991.814)"
                                                                                                          gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#fff"/><stop offset=".23" stop-color="#e57252"/><stop offset=".46"
                                                                                         stop-color="#de3b20"/><stop
            offset=".99" stop-color="#a60003"/><stop offset="1" stop-color="#a60003"/></linearGradient><linearGradient
            id="e" x1="-235.314" x2="-235.31" y1="-309.534" y2="-309.607"
            gradientTransform="matrix(105.32 0 0 -106.825 24798.925 -33053.152)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#fff"/><stop offset=".23" stop-color="#e4714e"/><stop offset=".56"
                                                                                         stop-color="#be1a0d"/><stop
            offset=".99" stop-color="#a80d00"/><stop offset="1" stop-color="#a80d00"/></linearGradient><linearGradient
            id="f" x1="-235.882" x2="-235.869" y1="-311.851" y2="-311.935"
            gradientTransform="matrix(94.321 0 0 -66.418 22271.499 -20707.004)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#fff"/><stop offset=".18" stop-color="#e46342"/><stop offset=".4"
                                                                                         stop-color="#c82410"/><stop
            offset=".99" stop-color="#a80d00"/><stop offset="1" stop-color="#a80d00"/></linearGradient><linearGradient
            id="g" x1="-235.412" x2="-235.333" y1="-321.074" y2="-320.958"
            gradientTransform="matrix(70.767 0 0 -24.301 16678.116 -7798.647)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#fff"/><stop offset=".54" stop-color="#c81f11"/><stop offset=".99"
                                                                                         stop-color="#bf0905"/><stop
            offset="1" stop-color="#bf0905"/></linearGradient><linearGradient id="h" x1="-223.821" x2="-223.796"
                                                                              y1="-310.116" y2="-310.18"
                                                                              gradientTransform="matrix(18.177 0 0 -72.645 4071.017 -22510.233)"
                                                                              gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#fff"/><stop offset=".31" stop-color="#de4024"/><stop offset=".99"
                                                                                         stop-color="#bf190b"/><stop
            offset="1" stop-color="#bf190b"/></linearGradient><linearGradient id="i" x1="-235.561" x2="-235.424"
                                                                              y1="-309.258" y2="-309.116"
                                                                              gradientTransform="matrix(158.162 0 0 -157.937 37256.313 -48819.382)"
                                                                              gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#bd0012"/><stop offset=".07" stop-color="#fff"/><stop offset=".17"
                                                                                         stop-color="#fff"/><stop
            offset=".27" stop-color="#c82f1c"/><stop offset=".33" stop-color="#820c01"/><stop offset=".46"
                                                                                              stop-color="#a31601"/><stop
            offset=".72" stop-color="#b31301"/><stop offset=".99" stop-color="#e82609"/><stop offset="1"
                                                                                              stop-color="#e82609"/></linearGradient><linearGradient
            id="j" x1="-235.424" x2="-235.476" y1="-309.143" y2="-309.126"
            gradientTransform="matrix(127.074 0 0 -97.409 29932.229 -30086.947)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#8c0c01"/><stop offset=".54" stop-color="#990c00"/><stop offset=".99"
                                                                                            stop-color="#a80d0e"/><stop
            offset="1" stop-color="#a80d0e"/></linearGradient><linearGradient id="k" x1="-235.839" x2="-235.901"
                                                                              y1="-309.604" y2="-309.555"
                                                                              gradientTransform="matrix(94.011 0 0 -105.603 22198.743 -32676.856)"
                                                                              gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#7e110b"/><stop offset=".99" stop-color="#9e0c00"/><stop offset="1"
                                                                                            stop-color="#9e0c00"/></linearGradient><linearGradient
            id="l" x1="-235.854" x2="-235.891" y1="-311.24" y2="-311.202"
            gradientTransform="matrix(79.702 0 0 -81.791 18827.397 -25447.905)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#79130d"/><stop offset=".99" stop-color="#9e120b"/><stop offset="1"
                                                                                            stop-color="#9e120b"/></linearGradient><linearGradient
            id="o" x1="-231.241" x2="-231.299" y1="-309.435" y2="-309.337"
            gradientTransform="matrix(40.137 0 0 -81.143 9286.998 -25078.589)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#8b2114"/><stop offset=".43" stop-color="#9e100a"/><stop offset=".99"
                                                                                            stop-color="#b3100c"/><stop
            offset="1" stop-color="#b3100c"/></linearGradient><linearGradient id="p" x1="-235.898" x2="-235.831"
                                                                              y1="-317.466" y2="-317.537"
                                                                              gradientTransform="matrix(78.099 0 0 -32.624 18447.361 -10353.553)"
                                                                              gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#b31000"/><stop offset=".44" stop-color="#910f08"/><stop offset=".99"
                                                                                            stop-color="#791c12"/><stop
            offset="1" stop-color="#791c12"/></linearGradient><radialGradient id="m" cx="-235.882" cy="-312.543"
                                                                              r=".076"
                                                                              gradientTransform="matrix(93.113 0 0 -48.655 21986.073 -15193.61)"
                                                                              gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#a80d00"/><stop offset=".99" stop-color="#7e0e08"/><stop offset="1"
                                                                                            stop-color="#7e0e08"/></radialGradient><radialGradient
            id="n" cx="-235.282" cy="-309.704" r=".097"
            gradientTransform="matrix(97.434 0 0 -75.848 22937.057 -23467.84)" gradientUnits="userSpaceOnUse"><stop
            offset="0" stop-color="#a30c00"/><stop offset=".99" stop-color="#800e08"/><stop offset="1"
                                                                                            stop-color="#800e08"/></radialGradient></defs><path
            fill="url(#b)" d="M23.693 20.469 7.707 29.961l20.7-1.4L30 7.685Z"/><path fill="url(#a)"
                                                                                     d="m28.44 28.542-1.779-12.279-4.846 6.4Z"/><path
            fill="url(#c)" d="M28.464 28.542 15.43 27.519l-7.654 2.415Z"/><path fill="url(#d)"
                                                                                d="M7.794 29.937 11.05 19.27 3.885 20.8Z"/><path
            fill="url(#e)" d="m21.813 22.7-3-11.735L10.243 19Z"/><path fill="url(#f)"
                                                                       d="m29.32 11.127-8.1-6.619-2.257 7.3Z"/><path
            fill="url(#g)" d="m25.53 2.148-4.767 2.634-3.007-2.67Z"/><path fill="url(#h)"
                                                                           d="m2 24.38 2-3.642L2.382 16.4Z"/><path
            fill="#fff"
            d="m2.274 16.263 1.626 4.61 7.062-1.584 8.062-7.489L21.3 4.569l-3.583-2.53-6.091 2.28C9.706 6.1 5.982 9.635 5.848 9.7s-2.459 4.464-3.574 6.562Z"/><path
            fill="url(#i)"
            d="M7.981 7.981C12.14 3.858 17.5 1.421 19.559 3.5s-.124 7.121-4.283 11.244-9.455 6.69-11.511 4.614.057-7.258 4.216-11.377"/><path
            fill="url(#j)" d="m7.794 29.933 3.231-10.7 10.729 3.447c-3.879 3.638-8.194 6.713-13.96 7.254Z"/><path
            fill="url(#k)" d="m19.038 11.774 2.754 10.91c3.24-3.407 6.149-7.07 7.573-11.6z"/><path fill="url(#l)"
                                                                                                   d="M29.337 11.139c1.1-3.327 1.357-8.1-3.841-8.985l-4.265 2.355z"/><path
            fill="#9e1209" d="M2 24.332c.153 5.49 4.114 5.572 5.8 5.62l-3.9-9.1z"/><path fill="url(#m)"
                                                                                         d="M19.053 11.791c2.49 1.531 7.509 4.6 7.61 4.661a17.6 17.6 0 0 0 2.619-5.343z"/><path
            fill="url(#n)" d="m11.021 19.232 4.319 8.332a28 28 0 0 0 6.385-4.88l-10.7-3.452Z"/><path fill="url(#o)"
                                                                                                     d="m3.887 20.861-.612 7.287c1.155 1.577 2.743 1.714 4.409 1.591-1.205-3-3.614-9-3.8-8.878Z"/><path
            fill="url(#p)" d="m21.206 4.528 8.58 1.2c-.458-1.94-1.864-3.192-4.261-3.584l-4.319 2.38Z"/></svg>
        <span class="lib-name">inertia_rails:</span>
        <span class="version-number">{{ railsVersion.version }}</span>
      </span>
    </template>

    <template v-if="coreVersion">
      <span class="version-badge" title="@inertiajs/core"
            aria-label="@inertiajs/core version {{ coreVersion.version }}">
        <!-- JavaScript Logo SVG -->
        <svg class="logo-svg js-logo" viewBox="0 0 128 128" width="16" height="16" aria-hidden="true" focusable="false">
          <path fill="#F0DB4F" d="M1.408 1.408h125.184v125.185h-125.184z"></path>
          <path fill="#323330"
                d="M116.347 96.736c-.917-5.711-4.641-10.508-15.672-14.981-3.832-1.761-8.104-3.022-9.377-5.926-.452-1.69-.512-2.642-.226-3.665.821-3.32 4.784-4.355 7.925-3.403 2.023.678 3.938 2.237 5.093 4.724 5.402-3.498 5.391-3.475 9.163-5.879-1.381-2.141-2.118-3.129-3.022-4.045-3.249-3.629-7.676-5.498-14.756-5.355l-3.688.477c-3.534.893-6.902 2.748-8.877 5.235-5.926 6.724-4.236 18.492 2.975 23.335 7.104 5.332 17.54 6.545 18.873 11.531 1.297 6.104-4.486 8.08-10.234 7.378-4.236-.881-6.592-3.034-9.139-6.949-4.688 2.713-4.688 2.713-9.508 5.485 1.143 2.499 2.344 3.63 4.26 5.795 9.068 9.198 31.76 8.746 35.83-5.176.165-.478 1.261-3.666.38-8.581zm-46.885-37.793h-11.709l-.048 30.272c0 6.438.333 12.34-.714 14.149-1.713 3.558-6.152 3.117-8.175 2.427-2.059-1.012-3.106-2.451-4.319-4.485-.333-.584-.583-1.036-.667-1.071l-9.52 5.83c1.583 3.249 3.915 6.069 6.902 7.901 4.462 2.678 10.459 3.499 16.731 2.059 4.082-1.189 7.604-3.652 9.448-7.401 2.666-4.915 2.094-10.864 2.07-17.444.06-10.735.001-21.468.001-32.237z"></path>
        </svg>
        <span class="lib-name">@inertiajs/core:</span>
        <span class="version-number">{{ coreVersion.version }}</span>
      </span>
    </template>

    <span v-if="description" class="description">{{ description }}</span>

    <div v-if="$slots.default" class="content">
      <slot></slot>
    </div>
  </div>
</template>

<style scoped>
.available-since {
  position: relative;
  margin: 12px 0;
  font-size: 15px;
  transition: opacity 0.2s ease;
  display: inline-flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.label {
  font-size: 0.9em;
  font-weight: 700;
  color: var(--vp-c-text-1);
  white-space: nowrap;
}

.version-badge {
  display: inline-flex;
  align-items: center;
  font-size: 0.75em;
  color: var(--vp-c-brand-1);
  font-family: var(--vp-font-family-mono);
  white-space: nowrap;
  background-color: var(--vp-c-brand-soft);
  border-radius: 12px;
  padding: 3px 10px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
  position: relative;
}

.version-badge:hover {
  background-color: var(--vp-c-brand-2);
  color: var(--vp-c-white);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.version-number {
  margin-left: 4px;
  transition: all 0.3s ease;
}

.lib-name {
  margin-left: 6px;
  font-weight: 500;
}

.logo-svg {
  display: inline-block;
  vertical-align: middle;
  margin-right: 2px;
}

.ruby-logo {
  filter: drop-shadow(0 1px 2px rgba(204, 52, 45, 0.3));
}

.js-logo {
  filter: drop-shadow(0 1px 2px rgba(240, 219, 79, 0.3));
}

.description {
  color: var(--vp-c-text-2);
  font-size: 0.9em;
  line-height: 1.4;
  margin: 0;
}

.content {
  position: relative;
  width: 100%;
  margin-top: 8px;
  font-size: 0.9em;
  padding-top: 8px;
  border-top: 1px solid var(--vp-c-divider);
}

@media (max-width: 640px) {
  .available-since {
    gap: 6px;
    flex-direction: column;
    align-items: flex-start;
  }

  .logo-svg {
    margin-right: 4px;
  }
}
</style>
